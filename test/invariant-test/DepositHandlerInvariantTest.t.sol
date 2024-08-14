// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TSwapPool} from "../../src/PoolFactory.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DepositHandler} from "./DepositHandler.t.sol";

contract DepositHandlerInvariantTest is StdInvariant, Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;
    DepositHandler depositHandler;
    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");
    uint256 public constant LP_STARTING_BALANCE = 200e18;
    uint256 public constant LP_INITIAL_DEPOSIT = 100e18;
    uint256 public constant USER_STARTING_BALANCE = 10e18;
    uint256 public MINIMUM_WETH_DEPOSIT;
    uint256 public constant PRECISION = 1e18;

    function setUp() external {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(
            address(poolToken),
            address(weth),
            "LTokenA",
            "LA"
        );
        MINIMUM_WETH_DEPOSIT = pool.getMinimumWethDepositAmount();
        depositHandler = new DepositHandler(pool, poolToken, weth);

        weth.mint(liquidityProvider, LP_STARTING_BALANCE);
        poolToken.mint(liquidityProvider, LP_STARTING_BALANCE);

        // the test contract will be the first  liquidity provider
        weth.mint(address(this), LP_STARTING_BALANCE * 2);
        poolToken.mint(address(this), LP_STARTING_BALANCE);
        weth.approve(address(pool), LP_STARTING_BALANCE);
        poolToken.approve(address(pool), LP_STARTING_BALANCE);
        pool.deposit(
            LP_STARTING_BALANCE,
            LP_STARTING_BALANCE,
            LP_STARTING_BALANCE,
            uint64(block.timestamp)
        );

        // user has been minted
        weth.mint(user, USER_STARTING_BALANCE);
        poolToken.mint(user, USER_STARTING_BALANCE);
        vm.deal(user, USER_STARTING_BALANCE);
        /// TODO: add invariant target contract
        console.log("address of deposit handler: ", address(depositHandler));
        targetContract(address(depositHandler));
        targetSender(address(user));
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = depositHandler.userCanSwap.selector;
        selectors[1] = depositHandler.doNothing.selector;
    }

    function invariant_hanlderUserCanSwap() public {
        uint256 wethBalanceOfUser = weth.balanceOf(user);
        console.log("weth balance of user", wethBalanceOfUser);
        console.log("number of user swaps", depositHandler.countUserSwap());
        assert(wethBalanceOfUser > 1);
    }

    function invariant_doingnothing() public {
        uint256 wethBalanceOfUser = weth.balanceOf(user);
        assert(wethBalanceOfUser > 1);
        assertGt(depositHandler.count(), 0);
    }
}
