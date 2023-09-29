// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {
    Bootstrap, SMv2SessionValidationModule
} from "test/utils/Bootstrap.sol";
import {IAccount} from "src/kwenta/smv2/IAccount.sol";

contract SMv2SessionValidationModuleTest is Bootstrap {
    address sessionKey;
    address smv2ProxyAccount;
    bytes4 smv2ExecuteSelector;
    address destinationContract;
    uint256 callValue;
    bytes funcCallData;
    bytes sessionKeyData;
    bytes callSpecificData;

    function setUp() public {
        initializeOptimismGoerli();

        // session key data
        sessionKey = address(0x1);
        smv2ProxyAccount = address(0x2);
        smv2ExecuteSelector = IAccount.execute.selector;

        // params
        destinationContract = smv2ProxyAccount;
        callValue = 0;
        funcCallData = abi.encode(smv2ExecuteSelector, bytes4(""));
        sessionKeyData =
            abi.encode(sessionKey, smv2ProxyAccount, smv2ExecuteSelector);
        callSpecificData = "";
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
        assertTrue(false);
    }

    function test_validateSessionUserOp_op_invalid() public {
        assertTrue(false);
    }

    function test_validateSessionUserOp_userOpHash_invalid() public {
        assertTrue(false);
    }

    function test_validateSessionUserOp_sessionKeyData_invalid() public {
        assertTrue(false);
    }

    function test_validateSessionUserOp_sessionKeySignature_invalid() public {
        assertTrue(false);
    }
}
