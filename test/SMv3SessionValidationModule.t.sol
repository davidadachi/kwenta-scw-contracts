// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {
    Bootstrap, SMv3SessionValidationModule
} from "test/utils/Bootstrap.sol";
import {
    UserOperationSignature,
    UserOperation,
    UserOperationLib
} from "test/utils/UserOperationSignature.sol";
import {IEngine} from "src/kwenta/smv3/IEngine.sol";
import {IERC7412} from "src/kwenta/smv3/IERC7412.sol";

contract SMv3SessionValidationModuleTest is Bootstrap {
    address signer;
    uint256 signerPrivateKey;
    address bad_signer;
    uint256 bad_signerPrivateKey;

    address sessionKey;
    address smv3Engine;
    bytes4 smv3ModifyCollateralSelector;
    bytes4 smv3CommitOrderSelector;
    bytes4 smv3InvalidateUnorderedNoncesSelector;
    bytes4 smv3FulfillOracleQuerySelector;
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
        smv3Engine = address(0x2);
        smv3ModifyCollateralSelector = IEngine.modifyCollateral.selector;
        smv3CommitOrderSelector = IEngine.commitOrder.selector;
        smv3InvalidateUnorderedNoncesSelector =
            IEngine.invalidateUnorderedNonces.selector;
        smv3FulfillOracleQuerySelector = IERC7412.fulfillOracleQuery.selector;

        // validateSessionParams params
        destinationContract = smv3Engine;
        callValue = 0;
        funcCallData = abi.encode(smv3ModifyCollateralSelector, bytes32(""));
        sessionKeyData = abi.encode(
            sessionKey,
            smv3Engine,
            smv3ModifyCollateralSelector,
            smv3CommitOrderSelector,
            smv3InvalidateUnorderedNoncesSelector,
            smv3FulfillOracleQuerySelector
        );
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

contract ValidateSessionParams is SMv3SessionValidationModuleTest {
    function test_validateSessionParams() public {
        funcCallData = abi.encode(smv3ModifyCollateralSelector, bytes32(""));
        address retSessionKey = smv3SessionValidationModule
            .validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );

        assertEq(sessionKey, retSessionKey);

        funcCallData = abi.encode(smv3CommitOrderSelector, bytes32(""));
        retSessionKey = smv3SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );

        assertEq(sessionKey, retSessionKey);

        funcCallData =
            abi.encode(smv3InvalidateUnorderedNoncesSelector, bytes32(""));
        retSessionKey = smv3SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );

        assertEq(sessionKey, retSessionKey);

        funcCallData = abi.encode(smv3FulfillOracleQuerySelector, bytes32(""));
        retSessionKey = smv3SessionValidationModule.validateSessionParams(
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
                SMv3SessionValidationModule.InvalidDestinationContract.selector
            )
        );

        smv3SessionValidationModule.validateSessionParams(
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
                SMv3SessionValidationModule.InvalidCallValue.selector
            )
        );

        smv3SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );
    }

    function test_validateSessionParams_funcCallData_invalid() public {
        funcCallData = abi.encodeWithSelector(bytes4(""), bytes32(""));

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSMv3Selector.selector
            )
        );

        smv3SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );
    }

    function test_validateSessionParams_sessionKeyData_invalid() public {
        sessionKeyData = abi.encode(
            sessionKey,
            address(0),
            smv3ModifyCollateralSelector,
            smv3CommitOrderSelector,
            smv3InvalidateUnorderedNoncesSelector,
            smv3FulfillOracleQuerySelector
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidDestinationContract.selector
            )
        );

        smv3SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );

        funcCallData = abi.encode(smv3ModifyCollateralSelector, bytes32(""));
        sessionKeyData = abi.encode(
            sessionKey,
            smv3Engine,
            bytes4(""),
            smv3CommitOrderSelector,
            smv3InvalidateUnorderedNoncesSelector,
            smv3FulfillOracleQuerySelector
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSMv3Selector.selector
            )
        );

        smv3SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );

        funcCallData = abi.encode(smv3CommitOrderSelector, bytes32(""));
        sessionKeyData = abi.encode(
            sessionKey,
            smv3Engine,
            smv3ModifyCollateralSelector,
            bytes4(""),
            smv3InvalidateUnorderedNoncesSelector,
            smv3FulfillOracleQuerySelector
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSMv3Selector.selector
            )
        );

        smv3SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );

        funcCallData =
            abi.encode(smv3InvalidateUnorderedNoncesSelector, bytes32(""));
        sessionKeyData = abi.encode(
            sessionKey,
            smv3Engine,
            smv3ModifyCollateralSelector,
            smv3CommitOrderSelector,
            bytes4(""),
            smv3FulfillOracleQuerySelector
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSMv3Selector.selector
            )
        );

        smv3SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );

        funcCallData = abi.encode(smv3FulfillOracleQuerySelector, bytes32(""));
        sessionKeyData = abi.encode(
            sessionKey,
            smv3Engine,
            smv3ModifyCollateralSelector,
            smv3CommitOrderSelector,
            smv3InvalidateUnorderedNoncesSelector,
            bytes4("")
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSMv3Selector.selector
            )
        );

        smv3SessionValidationModule.validateSessionParams(
            destinationContract,
            callValue,
            funcCallData,
            sessionKeyData,
            callSpecificData
        );
    }
}

contract ValidateSessionUserOp is SMv3SessionValidationModuleTest {
    function test_validateSessionUserOp() public {
        funcCallData = abi.encode(smv3ModifyCollateralSelector, bytes32(""));
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );
        userOpHash = userOpSignature.hashUserOperation(op);
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, signerPrivateKey);
        bool ret = smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        assertTrue(ret);

        funcCallData = abi.encode(smv3CommitOrderSelector, bytes32(""));
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );
        userOpHash = userOpSignature.hashUserOperation(op);
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, signerPrivateKey);
        ret = smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        assertTrue(ret);

        funcCallData =
            abi.encode(smv3InvalidateUnorderedNoncesSelector, bytes32(""));
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );
        userOpHash = userOpSignature.hashUserOperation(op);
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, signerPrivateKey);
        ret = smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        assertTrue(ret);

        funcCallData = abi.encode(smv3FulfillOracleQuerySelector, bytes32(""));
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );
        userOpHash = userOpSignature.hashUserOperation(op);
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, signerPrivateKey);
        ret = smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        assertTrue(ret);

        op.callData = abi.encodeWithSelector(
            EXECUTE_OPTIMIZED_SELECTOR,
            destinationContract,
            callValue,
            funcCallData
        );
        userOpHash = userOpSignature.hashUserOperation(op);
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, signerPrivateKey);

        ret = smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        assertTrue(ret);
    }

    function test_validateSessionUserOp_op_callData_invalid() public {
        op.callData = abi.encodeWithSelector(
            bytes4(""), destinationContract, callValue, funcCallData
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSelector.selector
            )
        );

        smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, address(0), callValue, funcCallData
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidDestinationContract.selector
            )
        );

        smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, 1, funcCallData
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidCallValue.selector
            )
        );

        smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR,
            destinationContract,
            callValue,
            abi.encode(bytes4(""), bytes4(""))
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSMv3Selector.selector
            )
        );

        smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );
    }

    function test_validateSessionUserOp_userOpHash_invalid() public {
        bytes32 invalidUserOpHash = bytes32("");
        bool ret = smv3SessionValidationModule.validateSessionUserOp(
            op, invalidUserOpHash, sessionKeyData, sessionKeySignature
        );

        assertFalse(ret);
    }

    function test_validateSessionUserOp_sessionKeyData_invalid() public {
        address invalidSessionKey = address(0);
        sessionKeyData = abi.encode(
            invalidSessionKey,
            smv3Engine,
            smv3ModifyCollateralSelector,
            smv3CommitOrderSelector,
            smv3InvalidateUnorderedNoncesSelector,
            smv3FulfillOracleQuerySelector
        );

        bool ret = smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        assertFalse(ret);

        sessionKeyData = abi.encode(
            sessionKey,
            address(0),
            smv3ModifyCollateralSelector,
            smv3CommitOrderSelector,
            smv3InvalidateUnorderedNoncesSelector,
            smv3FulfillOracleQuerySelector
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidDestinationContract.selector
            )
        );

        smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        funcCallData = abi.encode(smv3ModifyCollateralSelector, bytes32(""));
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );
        userOpHash = userOpSignature.hashUserOperation(op);
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, signerPrivateKey);
        sessionKeyData = abi.encode(
            sessionKey,
            smv3Engine,
            bytes4(""),
            smv3CommitOrderSelector,
            smv3InvalidateUnorderedNoncesSelector,
            smv3FulfillOracleQuerySelector
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSMv3Selector.selector
            )
        );

        smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        funcCallData = abi.encode(smv3CommitOrderSelector, bytes32(""));
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );
        userOpHash = userOpSignature.hashUserOperation(op);
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, signerPrivateKey);
        sessionKeyData = abi.encode(
            sessionKey,
            smv3Engine,
            smv3ModifyCollateralSelector,
            bytes4(""),
            smv3InvalidateUnorderedNoncesSelector,
            smv3FulfillOracleQuerySelector
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSMv3Selector.selector
            )
        );

        smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        funcCallData =
            abi.encode(smv3InvalidateUnorderedNoncesSelector, bytes32(""));
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );
        userOpHash = userOpSignature.hashUserOperation(op);
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, signerPrivateKey);
        sessionKeyData = abi.encode(
            sessionKey,
            smv3Engine,
            smv3ModifyCollateralSelector,
            smv3CommitOrderSelector,
            bytes4(""),
            smv3FulfillOracleQuerySelector
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSMv3Selector.selector
            )
        );

        smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        funcCallData = abi.encode(smv3FulfillOracleQuerySelector, bytes32(""));
        op.callData = abi.encodeWithSelector(
            EXECUTE_SELECTOR, destinationContract, callValue, funcCallData
        );
        userOpHash = userOpSignature.hashUserOperation(op);
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, signerPrivateKey);
        sessionKeyData = abi.encode(
            sessionKey,
            smv3Engine,
            smv3ModifyCollateralSelector,
            smv3CommitOrderSelector,
            smv3InvalidateUnorderedNoncesSelector,
            bytes4("")
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SMv3SessionValidationModule.InvalidSMv3Selector.selector
            )
        );

        smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );
    }

    function test_validateSessionUserOp_sessionKeySignature_invalid() public {
        sessionKeySignature =
            userOpSignature.getUserOperationSignature(op, bad_signerPrivateKey);
        bool ret = smv3SessionValidationModule.validateSessionUserOp(
            op, userOpHash, sessionKeyData, sessionKeySignature
        );

        assertFalse(ret);
    }
}
