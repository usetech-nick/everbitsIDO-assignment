// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./EverbitsToken.sol";
import "./interfaces/IEverbitsToken.sol";
import "./interfaces/ILaunchpadFactory.sol";

contract EverbitsIDO is Ownable {
    event Contribution(address indexed contributor, uint256 amount);
    event Withdrawal(address indexed contributor, uint256 amount);
    event IdoEnded(bool successful);
    event LiquidityWithdrawn(uint256 amount);

    IUniswapV2Router02 public uniswapV2Router;
    IEverbitsToken public token;
    StandardIDOParams public idoParams;
    ILaunchpadFactory public launchpadFactory;

    address public idoOwner;
    uint256 public idoBalance;
    bool public idoEnded;
    bool public idoSuccessful;

    mapping(address => uint256) public contributions;

    constructor(
        address _uinswapV2Router,
        address owner,
        StandardIDOParams memory _idoParams
    ) Ownable(msg.sender) {
        uniswapV2Router = IUniswapV2Router02(_uinswapV2Router);
        launchpadFactory = ILaunchpadFactory(msg.sender);
        idoOwner = owner;
        idoParams = _idoParams;

        if (
            _idoParams.liquidityLockDuration >
            type(uint256).max - _idoParams.endTimestamp
        ) {
            idoParams.liquidityLockDuration =
                type(uint256).max -
                _idoParams.endTimestamp;
        }
    }

    function contribute(uint256 amount) external {
        require(
            block.timestamp >= idoParams.startTimestamp,
            "IDO not started yet"
        );
        require(block.timestamp <= idoParams.endTimestamp, "IDO ended");
        require(amount > 0, "Amount must be greater than 0");
        require(idoBalance + amount <= idoParams.hardCap, "Hard cap reached");

        contributions[msg.sender] += amount;
        idoBalance += amount;

        emit Contribution(msg.sender, amount);
    }

    function withdraw() external {
        require(idoEnded, "IDO not ended yet");
        require(contributions[msg.sender] > 0, "No contribution");

        uint256 contribution = contributions[msg.sender];
        contributions[msg.sender] = 0;

        if (idoSuccessful) {
            uint256 tokens = (contribution * idoParams.idoSupply) / idoBalance;
            token.mint(msg.sender, tokens);
        } else {
            (bool success, ) = payable(msg.sender).call{value: contribution}(
                ""
            );
            require(success, "Transfer failed");
        }

        emit Withdrawal(msg.sender, contribution);
    }

    function endIdo() external {
        require(block.timestamp >= idoParams.endTimestamp, "IDO not ended yet");
        if (idoBalance >= idoParams.softCap) {
            token = IEverbitsToken(
                address(new EverbitsToken(idoParams.name, idoParams.symbol))
            );

            idoSuccessful = true;

            // Transfer ETH fee to everbits
            uint256 successFee = (idoBalance * 3) / 100;
            (bool success, ) = payable(launchpadFactory.getEverbitsTreasury())
                .call{value: successFee}("");
            require(success, "Transfer failed");

            // Add liquidity
            uint256 liquidityAmount = (idoBalance *
                idoParams.liquidityPercentage) / 100_00;
            token.mint(address(this), liquidityAmount);
            token.approve(address(uniswapV2Router), liquidityAmount);
            uniswapV2Router.addLiquidityETH{value: address(this).balance}(
                address(token),
                liquidityAmount,
                0,
                0,
                address(this),
                block.timestamp
            );
            // Transfer remaining tokens to owner
            token.transfer(idoOwner, token.balanceOf(address(this)));

            // mint tokens to owner
            token.mint(idoOwner, idoParams.totalSupply - idoParams.idoSupply);
        } else {
            idoSuccessful = false;
        }
        idoEnded = true;

        emit IdoEnded(idoSuccessful);
    }

    function withdrawLiquidity() external onlyOwner {
        require(idoEnded, "IDO not ended yet");
        require(idoSuccessful, "IDO not successful");
        require(
            block.timestamp >=
                idoParams.endTimestamp + idoParams.liquidityLockDuration,
            "Liquidity locked"
        );

        IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(
            uniswapV2Router.factory()
        );
        ERC20 liquidityToken = ERC20(
            uniswapV2Factory.getPair(address(token), uniswapV2Router.WETH())
        );
        uint256 liquidityAmount = liquidityToken.balanceOf(address(this));

        token.approve(address(uniswapV2Router), liquidityAmount);
        uniswapV2Router.removeLiquidityETH(
            address(token),
            liquidityAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed");

        emit LiquidityWithdrawn(liquidityAmount);
    }
}
