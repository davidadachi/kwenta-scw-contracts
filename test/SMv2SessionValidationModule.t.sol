// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {
    Bootstrap, SMv2SessionValidationModule
} from "test/utils/Bootstrap.sol";
import {
    UserOperationSignature,
    UserOperation,
    UserOperationLib
} from "test/utils/UserOperationSignature.sol";
import {IAccount} from "src/kwenta/smv2/IAccount.sol";

contract SMv2SessionValidationModuleTest is Bootstrap {
    address signer;
    uint256 signerPrivateKey;
    address bad_signer;
    uint256 bad_signerPrivateKey;

    address sessionKey;
    address smv2ProxyAccount;
    bytes4 smv2ExecuteSelector;
    address destinationContract;
    uint256 callValue;
    bytes funcCallData;
    bytes sessionKeyData;
    bytes sessionKeySignature;
    bytes callSpecificData;

    bytes4 public constant EXECUTE_SELECTOR = 0xb61d27f6;
    bytes4 public constant EXECUTE_OPTIMIZED_SELECTOR = 0x0000189a;

    UserOperationSignature userOpSignature;
    UserOperation op;
    bytes32 userOpHash;
    bytes data;

    function setUp() public {
        initializeOptimismGoerli();

        userOpSignature = new UserOperationSignature();

        // signers
        signerPrivateKey = 0x12341234;
        signer = vm.addr(signerPrivateKey);
        bad_signerPrivateKey = 0x12341235;
        bad_signer = vm.addr(bad_signerPrivateKey);

        // session key data
        sessionKey = signer;
        smv2ProxyAccount = address(0x2);
        smv2ExecuteSelector = IAccount.execute.selector;

        // validateSessionParams params
        destinationContract = smv2ProxyAccount;
        callValue = 0;
        funcCallData = abi.encode(smv2ExecuteSelector, bytes32(""));
        sessionKeyData =
            abi.encode(sessionKey, smv2ProxyAccount, smv2ExecuteSelector);
        callSpecificData = "";

        // validateSessionUserOp params
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );
        userOpHash = userOpSignature.hashUserOperation(op);
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, signerPrivateKey);
    }
}

contract ValidateSessionParams is SMv2SessionValidationModuleTest {
    function test_validateSessionParams() public {
        address retSessionKey = smv2SessionValidationModule
            .validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );

        assertEq(sessionKey, retSessionKey);
    }

    function test_validateSessionParams_destinationContract_invalid() public {
        destinationContract = address(0);

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidDestinationContract.selector
            )
        );

        smv2SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );
    }

    function test_validateSessionParams_callValue_invalid() public {
        callValue = 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidCallValue.selector
            )
        );

        smv2SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );
    }

    function test_validateSessionParams_funcCallData_invalid() public {
        funcCallData = abi.encode(bytes4(""), bytes4(""));

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidSMv2Selector.selector
            )
        );

        smv2SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );
    }

    function test_validateSessionParams_sessionKeyData_invalid() public {
        address invalidSessionKey = address(0);
        sessionKeyData =
            abi.encode(invalidSessionKey, smv2ProxyAccount, smv2ExecuteSelector);

        address retSessionKey = smv2SessionValidationModule
            .validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );

        assertFalse(retSessionKey == sessionKey);

        address invalidSmv2ProxyAccount = address(0);
        sessionKeyData =
            abi.encode(sessionKey, invalidSmv2ProxyAccount, smv2ExecuteSelector);

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidDestinationContract.selector
            )
        );

        smv2SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );

        bytes4 invalidSmv2ExecuteSelector = bytes4("");
        sessionKeyData =
            abi.encode(sessionKey, smv2ProxyAccount, invalidSmv2ExecuteSelector);

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidSMv2Selector.selector
            )
        );

        smv2SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );
    }
}

contract ValidateSessionUserOp is SMv2SessionValidationModuleTest {
    function test_validateSessionUserOp() public {
        bool isValid = smv2SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        assertTrue(isValid);
    }

    function test_validateSessionUserOp_op_callData_invalid() public {
        bytes4 invalidSelector = bytes4("");
        op.callData = abi.encodeWithSelector(
            invalidSelector, smv2ProxyAccount, callValue, funcCallData
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidSelector.selector
            )
        );

        smv2SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        destinationContract = address(0);
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidDestinationContract.selector
            )
        );

        smv2SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        callValue = 1;
        destinationContract = smv2ProxyAccount;
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidCallValue.selector
            )
        );

        smv2SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        callValue = 0;
        funcCallData = abi.encode(bytes4(""), bytes4(""));
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidSMv2Selector.selector
            )
        );

        smv2SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );
    }

    function test_validateSessionUserOp_userOpHash_invalid() public {
        bytes32 invalidUserOpHash = bytes32("");
        bool isValid = smv2SessionValidationModule.validateSessionUserOp(
            op, invalidUserOpHash, sessionKeyData, sessionKeySignature
        );

        assertFalse(isValid);
    }

    function test_validateSessionUserOp_sessionKeyData_invalid() public {
        address invalidSessionKey = address(0);
        sessionKeyData =
            abi.encode(invalidSessionKey, smv2ProxyAccount, smv2ExecuteSelector);

        bool isValid = smv2SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        assertFalse(isValid);

        address invalidSmv2ProxyAccount = address(0);
        sessionKeyData =
            abi.encode(sessionKey, invalidSmv2ProxyAccount, smv2ExecuteSelector);

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidDestinationContract.selector
            )
        );

        smv2SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        bytes4 invalidSmv2ExecuteSelector = bytes4("");
        sessionKeyData =
            abi.encode(sessionKey, smv2ProxyAccount, invalidSmv2ExecuteSelector);

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv2SessionValidationModule.InvalidSMv2Selector.selector
            )
        );

        smv2SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );
    }

    function test_validateSessionUserOp_sessionKeySignature_invalid() public {
        bytes memory invalidSessionKeySignature =
            userOpSignature.getUserOperationSignature(op, bad_signerPrivateKey);
        bool isValid = smv2SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, invalidSessionKeySignature
        );

        assertFalse(isValid);
    }
}
