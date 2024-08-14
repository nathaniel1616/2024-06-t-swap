// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";


contract DepositHandler is Test {
    TSwapPool pool;
    IERC20 poolToken;
    IERC20 weth;
    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");
    uint256 public constant LP_STARTING_BALANCE = 200e18;
    uint256 public constant LP_INITIAL_DEPOSIT = 100e18;
    uint256 public constant USER_STARTING_BALANCE = 10e18;
    uint256 public MINIMUM_WETH_DEPOSIT;
    uint256 public MININUM_SWAP_AMOUHT = 0.01 ether;
    uint256 public constant PRECISION = 1e18;
    uint256 public LP_CURRENT_BALANCE;
    uint256 public constant FEES = 997;
    uint256 public constant FESS_PRECISION = 1000; 
    uint256 public countUserSwap;

    uint256 public count;
 

    constructor(TSwapPool _tSwapool, ERC20Mock _poolToken, ERC20Mock _weth) {
        pool = _tSwapool;
        poolToken = _poolToken;
        weth = _weth;
        MINIMUM_WETH_DEPOSIT = pool.getMinimumWethDepositAmount();
        LP_CURRENT_BALANCE = LP_STARTING_BALANCE;
        
    }

    function userCanSwap(uint256 _amount) public {  
        _amount = bound(_amount, MININUM_SWAP_AMOUHT, USER_STARTING_BALANCE/100 );
        if (_amount < MININUM_SWAP_AMOUHT) {
            return;
        } 
        console.log("amount of the param: ", _amount);

        vm.startPrank(user);
        weth.approve(address(pool), _amount);
        poolToken.approve(address(pool), _amount);

        // the expected output amount , remember to add fees to the protocol to it
        uint256 minOutputAmountExpected = (pool.getPoolTokensToDepositBasedOnWeth(_amount) * FEES ) / PRECISION;
        pool.swapExactInput(weth,_amount, poolToken, minOutputAmountExpected, uint64(block.timestamp)); 
        console.log("handler made deposit");
        countUserSwap++;

    
    }

    function doNothing(uint64 numbering) public {
        if (numbering > 2**63) {
            revert();
        }
        count ++;
    }

}