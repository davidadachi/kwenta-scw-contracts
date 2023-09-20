// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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
            address token,
            address recipient,
            uint256 maxAmount
        ) = abi.decode(_sessionKeyData, (address, address, address, uint256));

        require(destinationContract == token, "ERC20SV Invalid Token");
        require(callValue == 0, "ERC20SV Non Zero Value");

        (address recipientCalled, uint256 amount) =
            abi.decode(_funcCallData[4:], (address, uint256));

        require(recipient == recipientCalled, "ERC20SV Wrong Recipient");
        require(amount <= maxAmount, "ERC20SV Max Amount Exceeded");
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
        require(
            bytes4(_op.callData[0:4]) == EXECUTE_OPTIMIZED_SELECTOR
                || bytes4(_op.callData[0:4]) == EXECUTE_SELECTOR,
            "ERC20SV Invalid Selector"
        );

        (
            address sessionKey,
            address token,
            address recipient,
            uint256 maxAmount
        ) = abi.decode(_sessionKeyData, (address, address, address, uint256));

        {
            // we expect _op.callData to be `SmartAccount.execute(to, value, calldata)` calldata
            (address tokenAddr, uint256 callValue,) = abi.decode(
                _op.callData[4:], // skip selector
                (address, uint256, bytes)
            );

            if (tokenAddr != token) {
                revert("ERC20SV Wrong Token");
            }
            
            if (callValue != 0) {
                revert("ERC20SV Non Zero Value");
            }
        }
        // working with userOp.callData
        // check if the call is to the allowed recepient and amount is not more than allowed
        bytes calldata data;
        {
            uint256 offset = uint256(bytes32(_op.callData[4 + 64:4 + 96]));
            uint256 length =
                uint256(bytes32(_op.callData[4 + offset:4 + offset + 32]));
            //we expect data to be the `IERC20.transfer(address, uint256)` calldata
            data = _op.callData[4 + offset + 32:4 + offset + 32 + length];
        }

        if (address(bytes20(data[16:36])) != recipient) {
            revert("ERC20SV Wrong Recipient");
        }

        if (uint256(bytes32(data[36:68])) > maxAmount) {
            revert("ERC20SV Max Amount Exceeded");
        }

        /// @dev this method of signature validation is out-of-date and should be replaced
        /// see https://github.com/OpenZeppelin/openzeppelin-sdk/blob/7d96de7248ae2e7e81a743513ccc617a2e6bba21/packages/lib/contracts/cryptography/ECDSA.sol#L6
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(_userOpHash), _sessionKeySignature
        ) == sessionKey;
    }
}
