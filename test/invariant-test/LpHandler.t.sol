// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";

contract LpHandler is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;
    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");
    uint256 public constant LP_STARTING_BALANCE = 200e18;
    uint256 public constant LP_INITIAL_DEPOSIT = 100e18;
    uint256 public constant USER_STARTING_BALANCE = 10e18;
    uint256 public MINIMUM_WETH_DEPOSIT;
    uint256 public constant PRECISION = 1e18;
    uint256 public LP_CURRENT_BALANCE;
    uint256 public countLpDeposit;

    error Handler_LPCurrentDepositNotEnough(uint256 _amount);
    error Handler_MinimumAmountTooSmall(uint256 _amount);

    constructor(TSwapPool _tSwapool, ERC20Mock _poolToken, ERC20Mock _weth) {
        pool = _tSwapool;
        poolToken = _poolToken;
        weth = _weth;
        MINIMUM_WETH_DEPOSIT = pool.getMinimumWethDepositAmount();
        LP_CURRENT_BALANCE = LP_STARTING_BALANCE;
    }

    function LPCanDeposit(uint256 _amount) public {
        /// amount less than the required deposit
        _amount = bound(_amount, MINIMUM_WETH_DEPOSIT, LP_CURRENT_BALANCE / 100);
        if (_amount < MINIMUM_WETH_DEPOSIT) {
            revert Handler_MinimumAmountTooSmall(_amount);
        }
        // amount greater than the current balance
        if (_amount > LP_CURRENT_BALANCE) {
            revert Handler_LPCurrentDepositNotEnough(_amount);
        }
        LP_CURRENT_BALANCE -= _amount;
        console.log("amount of the param: ", _amount);
        console.log("remianing LP balance: ", LP_CURRENT_BALANCE);

        // starting prank and deposit
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), _amount);
        poolToken.approve(address(pool), _amount);
        pool.deposit(_amount, _amount, _amount, uint64(block.timestamp));
        console.log("handler made deposit");
        countLpDeposit++;
    }
}
