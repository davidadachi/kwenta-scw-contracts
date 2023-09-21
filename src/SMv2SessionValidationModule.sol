// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IAccount} from "lib/smart-margin/src/interfaces/IAccount.sol";
import {
    ISessionValidationModule,
    UserOperation
} from "src/biconomy/interfaces/ISessionValidationModule.sol";
import {ECDSA} from "src/openzeppelin/ECDSA.sol";

/**
 * @title Kwenta Smart Margin v2 Session Validation Module for Biconomy Smart Accounts.
 * @dev Validates userOps for `Account.execute()` using a session key signature.
 * @author Fil Makarov - <filipp.makarov@biconomy.io>
 * @author JaredBorders (jaredborders@pm.me)
 */

contract SMv2SessionValidationModule is ISessionValidationModule {
    error InvalidSelector(bytes4 selector);
    error InvalidSMv2ExecuteSelector(bytes4 selector);
    error InvalidDestinationContract(address addr);
    error InvalidCallValue();

    /**
     * @dev validates that the call (destinationContract, callValue, funcCallData)
     * complies with the Session Key permissions represented by sessionKeyData
     * @param destinationContract address of the contract to be called
     * @param callValue value to be sent with the call
     * @param _funcCallData the data for the call. is parsed inside the SVM
     * @param _sessionKeyData SessionKey data, that describes sessionKey permissions
     */
    function validateSessionParams(
        address destinationContract,
        uint256 callValue,
        bytes calldata _funcCallData,
        bytes calldata _sessionKeyData,
        bytes calldata /*_callSpecificData*/
    ) external virtual override returns (address) {
        (
            address sessionKey,
            address smv2ProxyAccount,
            bytes4 smv2ExecuteSelector
        ) = abi.decode(_sessionKeyData, (address, address, bytes4));

        /// @dev ensure destinationContract is the SMv2ProxyAccount
        if (destinationContract != smv2ProxyAccount) {
            revert InvalidDestinationContract(smv2ProxyAccount);
        }

        /// @dev ensure the function selector is the `SmartAccount.execute` selector
        if (bytes4(_funcCallData[:4]) != smv2ExecuteSelector) {
            revert InvalidSMv2ExecuteSelector(smv2ExecuteSelector);
        }

        /// @dev ensure call value is zero
        if (callValue != 0) {
            revert InvalidCallValue();
        }

        // (IAccount.Command[] memory _commands, bytes[] memory _inputs) = abi.decode(
        //     _funcCallData[4:],
        //     (IAccount.Command[], bytes[])
        // );

        /// @custom:add-param-validation-here-if-needed

        return sessionKey;
    }

    /**
     * @dev validates if the _op (UserOperation) matches the SessionKey permissions
     * and that _op has been signed by this SessionKey
     * Please mind the decimals of your exact token when setting maxAmount
     * @param _op User Operation to be validated.
     * @param _userOpHash Hash of the User Operation to be validated.
     * @param _sessionKeyData SessionKey data, that describes sessionKey permissions
     * @param _sessionKeySignature Signature over the the _userOpHash.
     * @return true if the _op is valid, false otherwise.
     */
    function validateSessionUserOp(
        UserOperation calldata _op,
        bytes32 _userOpHash,
        bytes calldata _sessionKeyData,
        bytes calldata _sessionKeySignature
    ) external pure override returns (bool) {
        /// @dev ensure function selector is `IAccount.execute`
        if (
            bytes4(_op.callData[0:4]) != EXECUTE_SELECTOR
                || bytes4(_op.callData[0:4]) != EXECUTE_OPTIMIZED_SELECTOR
        ) {
            revert InvalidSelector(bytes4(_op.callData[0:4]));
        }

        (
            address sessionKey,
            address smv2ProxyAccount,
            bytes4 smv2ExecuteSelector
        ) = abi.decode(_sessionKeyData, (address, address, bytes4));

        {
            // we expect _op.callData to be `SmartAccount.execute(to, value, calldata)` calldata
            (address smv2ProxyAccountAddress, uint256 callValue,) = abi.decode(
                _op.callData[4:], // skip selector
                (address, uint256, bytes)
            );

            /// @dev ensure destinationContract is the SMv2ProxyAccount
            if (smv2ProxyAccountAddress != smv2ProxyAccount) {
                revert InvalidDestinationContract(smv2ProxyAccountAddress);
            }

            /// @dev ensure call value is zero
            if (callValue != 0) {
                revert InvalidCallValue();
            }
        }

        // working with userOp.callData
        // check if the call is conforms to `IAccount.execute`
        bytes calldata data;
        {
            uint256 offset = uint256(bytes32(_op.callData[4 + 64:4 + 96]));
            uint256 length =
                uint256(bytes32(_op.callData[4 + offset:4 + offset + 32]));
            // we expect data to be the `IAccount.execute(Command[] _commands, bytes[] _inputs)` calldata
            data = _op.callData[4 + offset + 32:4 + offset + 32 + length];
        }

        /// @dev ensure the function selector is the smv2ExecuteSelector selector
        if (bytes4(data[:4]) != smv2ExecuteSelector) {
            revert InvalidSMv2ExecuteSelector(smv2ExecuteSelector);
        }

        /// @dev this method of signature validation is out-of-date
        /// see https://github.com/OpenZeppelin/openzeppelin-sdk/blob/7d96de7248ae2e7e81a743513ccc617a2e6bba21/packages/lib/contracts/cryptography/ECDSA.sol#L6
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(_userOpHash), _sessionKeySignature
        ) == sessionKey;
    }
}
