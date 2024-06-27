// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";

contract DepositHandler is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;
    // address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");
    uint256 public constant LP_STARTING_BALANCE = 200e18;
    uint256 public constant LP_INITIAL_DEPOSIT = 100e18;
    uint256 public constant USER_STARTING_BALANCE = 10e18;
    uint256 public MINIMUM_WETH_DEPOSIT;
    uint256 public constant PRECISION = 1e18;
    uint256 public userCurrentBalance;
    uint256 public countUserDeposit;

    error DepositHandler_UserCurrentDepositNotEnough(uint256 _amount);

    constructor(TSwapPool _tSwapool, ERC20Mock _poolToken, ERC20Mock _weth) {
        pool = _tSwapool;
        poolToken = _poolToken;
        weth = _weth;

        userCurrentBalance = USER_STARTING_BALANCE;
    }

    function UserCanSwap(uint256 _amount) public {
        _amount = bound(_amount, 1, userCurrentBalance / 100);

        if (_amount > userCurrentBalance) {
            revert DepositHandler_UserCurrentDepositNotEnough(_amount);
        }
        console.log("amount of the param: ", _amount);
        console.log("remianing LP balance: ", userCurrentBalance);
        vm.startPrank(user);

        weth.approve(address(pool), _amount);
        poolToken.approve(address(pool), _amount);
        uint256 alpha = (_amount * PRECISION / LP_INITIAL_DEPOSIT);
        console.log("alpha: ", alpha);
        uint256 expected = (alpha * PRECISION / (PRECISION + alpha)) * LP_INITIAL_DEPOSIT / PRECISION;
        console.log("expected: ", expected);
        // we assume 5% fees
        expected = expected * 995 / 1000;
        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));

        console.log("handler made deposit");
        countUserDeposit++;
    }
}
