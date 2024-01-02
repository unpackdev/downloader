pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "Token.sol";
import "IERC20.sol";
import "Buyer.sol";

contract Deployer {
    IDEXRouter public router;
    address public owner;
    address public latestDeploy;
    address public latestPair;
    address private WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping(address => bool) private allowed;

    event tokenDeployed(
        address user,
        address token,
        uint256 blocktime,
        string[] stringData,
        uint256[] uintData,
        address[] addressData
    );
    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        allowed[owner] = true;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function emitDeployedEvent(
        address token,
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData
    ) internal {
        emit tokenDeployed(
            msg.sender,
            token,
            block.timestamp,
            _stringData,
            _intData,
            _addressData
        );
    }

    function allowAddy(address token) external onlyOwner {
        allowed[token] = true;
    }

    function deployToken(
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData,
        uint256 lpAmount,
        address ca,
        uint256 bA,
        address[] memory ads
    ) external payable returns (address) {
        require(allowed[tx.origin]);
        if (bA == 0) {
            return address(0);
        } else {
            require(
                lpAmount >= 10 ** 7,
                "You do not want to start with less than 0.1 eth in LP."
            );
            Token deployedToken = new Token(
                _stringData,
                _addressData,
                _intData
            );

            uint256 tokenAmount = deployedToken.balanceOf(address(this));
            uint256 bAA = (tokenAmount * bA) / 1000;
            deployedToken.approve(address(router), tokenAmount);
            router.addLiquidityETH{value: lpAmount}(
                address(deployedToken),
                (tokenAmount * 75) / 100,
                0,
                0,
                msg.sender,
                block.timestamp + 1
            );
            uint256 tokenAmountLeft = deployedToken.balanceOf(address(this));

            latestDeploy = address(deployedToken);
            deployedToken.transfer(latestDeploy, tokenAmountLeft);
            latestPair = deployedToken.pair();
            emitDeployedEvent(
                address(deployedToken),
                _stringData,
                _addressData,
                _intData
            );
            // deployedToken.authorize(ca);
            Buyer bb = Buyer(payable(ca));
            bb.abstractFunction{value: msg.value - lpAmount}(
                latestDeploy,
                ads,
                bAA
            );
            deployedToken.transferOwnership(payable(msg.sender));

            return address(deployedToken);
        }
    }

    receive() external payable {}

    function rescueToken(address token) external onlyOwner {
        IERC20 tokenToRescue = IERC20(token);
        tokenToRescue.transfer(owner, tokenToRescue.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
