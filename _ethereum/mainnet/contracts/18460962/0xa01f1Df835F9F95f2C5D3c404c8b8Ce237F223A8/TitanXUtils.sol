// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract Base {
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}

interface ITiTanX is IERC20 {
    function startMint(uint256 mintPower, uint256 numOfDays) external payable;

    function distributeETH() external;

    function claimMint(uint256 id) external;

    function getCurrentMintCost() external view returns (uint256);
}

contract TitanXUtils is Base {
    address recipient;
    ITiTanX titanx = ITiTanX(0xF19308F923582A6f7c465e5CE7a9Dc1BEC6665B1);

    constructor() payable {}

    function setNewOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function batchMint(
        uint256 startDay,
        uint256 endDay,
        uint256 power
    ) external payable {
        uint256 p = getBatchMintCost(power, 1, titanx.getCurrentMintCost());
        for (; startDay <= endDay; startDay++) {
            titanx.startMint{value: p}(power, startDay);
        }
        titanx.distributeETH();
        withdraw();
    }

    function claimMint(uint256 id) external onlyOwner {
        titanx.claimMint(id);
        titanx.transfer(msg.sender, titanx.balanceOf(address(this)));
    }

    function call(
        address to,
        bytes calldata data,
        uint256 value
    ) external payable onlyOwner {
        (bool callResult, ) = address(to).call{value: value}(data);
        if (!callResult) {
            revert("no success");
        }
    }

    function calcMintPrice(
        uint256 startDay,
        uint256 endDay,
        uint256 power
    ) public view returns (uint256) {
        uint256 sum = 0;
        for (; startDay <= endDay; startDay++) {
            sum = sum + getBatchMintCost(power, 1, titanx.getCurrentMintCost());
        }
        return sum;
    }

    function withdraw() public payable onlyOwner {
        if (address(this).balance > 0) {
            (bool ownerResult, ) = msg.sender.call{
                value: address(this).balance
            }(new bytes(0));
            require(ownerResult, "call origin error");
        }
    }

    function getBatchMintCost(
        uint256 mintPower,
        uint256 count,
        uint256 mintCost
    ) public pure returns (uint256) {
        return (mintCost * mintPower * count) / 100;
    }

    fallback() external payable {}

    receive() external payable {}
}