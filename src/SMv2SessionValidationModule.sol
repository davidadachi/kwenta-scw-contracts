// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ECDSA} from "src/openzeppelin/ECDSA.sol";
import {IAccount} from "src/kwenta/smv2/IAccount.sol";
import {
    ISessionValidationModule,
    UserOperation
} from "src/biconomy/interfaces/ISessionValidationModule.sol";

/**
 * @title Kwenta Smart Margin v2 Session Validation Module for Biconomy Smart Accounts
 * @author Fil Makarov - <filipp.makarov@biconomy.io>
 * @author JaredBorders (jaredborders@pm.me)
 */
contract SMv2SessionValidationModule is ISessionValidationModule {
    error InvalidSelector();
    error InvalidSMv2Selector();
    error InvalidDestinationContract();

    /**
     * @dev validates that the call (destinationContract, callValue, funcCallData)
     * complies with the Session Key permissions represented by sessionKeyData
     * @param destinationContract address of the contract to be called
     * @param _funcCallData the data for the call. is parsed inside the SVM
     * @param _sessionKeyData SessionKey data, that describes sessionKey permissions
     */
    function validateSessionParams(
        address destinationContract,
        uint256, /*callValue*/
        bytes calldata _funcCallData,
        bytes calldata _sessionKeyData,
        bytes calldata /*_callSpecificData*/
    ) external pure override returns (address) {
        (address sessionKey, address smv2ProxyAccount) =
            abi.decode(_sessionKeyData, (address, address));

        /// @dev ensure destinationContract is the SMv2ProxyAccount
        if (destinationContract != smv2ProxyAccount) {
            revert InvalidDestinationContract();
        }

        /// @dev ensure the function selector is the `IAccount.execute` selector
        if (bytes4(_funcCallData[0:4]) != IAccount.execute.selector) {
            revert InvalidSMv2Selector();
        }

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
                && bytes4(_op.callData[0:4]) != EXECUTE_OPTIMIZED_SELECTOR
        ) {
            revert InvalidSelector();
        }

        (address sessionKey, address smv2ProxyAccount) =
            abi.decode(_sessionKeyData, (address, address));

        (address destinationContract,,) = abi.decode(
            _op.callData[4:], // skip selector; already checked
            (address, uint256, bytes)
        );

        /// @dev ensure destinationContract is the SMv2ProxyAccount
        if (destinationContract != smv2ProxyAccount) {
            revert InvalidDestinationContract();
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

        /// @dev ensure the function selector is `IAccount.execute`
        if (bytes4(data[0:4]) != IAccount.execute.selector) {
            revert InvalidSMv2Selector();
        }

        /// @dev this method of signature validation is out-of-date
        /// see https://github.com/OpenZeppelin/openzeppelin-sdk/blob/7d96de7248ae2e7e81a743513ccc617a2e6bba21/packages/lib/contracts/cryptography/ECDSA.sol#L6
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(_userOpHash), _sessionKeySignature
        ) == sessionKey;
    }
}
