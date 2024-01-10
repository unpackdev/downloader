//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Pausable.sol";
import "./Badger.sol";

contract Karmic is Badger, Pausable {
    uint256 public constant FEE_PRECISION = 1 ether; // 10^18 = 100%
    uint256 public constant TOKENS_PER_ETH = 1000;

    mapping(address => BoxToken) public boxTokenTiers;

    uint256 public boxTokenCounter;
    uint256 public fee;

    struct BoxToken {
        uint256 id;
        uint256 amount;
        uint256 funds;
        uint256 distributed;
        bool passedThreshold;
        uint256 threshold;
    }

    event FundsDistributed(
        address indexed receiver,
        uint256 indexed tokenTier,
        uint256 amount
    );

    modifier isBoxToken(address token) {
        require(boxTokenTiers[token].id != 0, "It is not a box token");
        _;
    }

    constructor(string memory _newBaseUri, string memory _metadata, uint256 _fee) Badger(_newBaseUri) {
        boxTokenCounter = 1;
        fee = _fee;
        createTokenTier(0, _metadata, false, address(0));
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function bondToMint(address token, uint256 amount)
        public
        whenNotPaused
        isBoxToken(token)
    {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "transfer failed");
        bytes memory data;
        _mint(msg.sender, boxTokenTiers[token].id, amount/TOKENS_PER_ETH, data);
    }

    function addBoxTokens(
        address[] memory tokens,
        string[] calldata tierUris,
        uint256[] calldata threshold
    ) external onlyOwner {
        uint256 counter = boxTokenCounter;

        for (uint8 i; i < tokens.length; i++) {
            address token = tokens[i];
            require(boxTokenTiers[token].id == 0, "DUPLICATE_TOKEN");
            boxTokenTiers[token].id = counter;
            boxTokenTiers[token].threshold = threshold[i];
            createTokenTier(counter, tierUris[i], false, token);
            counter++;
        }

        boxTokenCounter = counter;
    }

    function withdraw(address token, uint256 amount) external whenNotPaused isBoxToken(token) {
        uint256 totalFunding = (boxTokenTiers[token].funds*FEE_PRECISION) / (FEE_PRECISION - fee);
        require(
            !(totalFunding >= boxTokenTiers[token].threshold),
            "Can withdraw only funds for tokens that didn't pass threshold"
        );
        uint256 withdrawnFunds = (amount * totalFunding) /
            boxTokenTiers[token].amount;
        boxTokenTiers[token].funds -= withdrawnFunds - withdrawnFunds*fee/FEE_PRECISION;
        boxTokenTiers[address(0)].funds -= withdrawnFunds*fee/FEE_PRECISION;
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "transfer failed");
        Address.sendValue(payable(msg.sender), withdrawnFunds);
    }

    function claimGovernanceTokens(address[] memory boxTokens) external whenNotPaused {
        bytes memory data;

        address token;
        for (uint8 i; i < boxTokens.length; i++) {
            token = boxTokens[i];
            uint256 amount = IERC20(token).balanceOf(msg.sender);
            uint256 tokenId = boxTokenTiers[token].id;
            require(tokenId != 0, "It is not a box token");
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "transfer failed");
            _mint(msg.sender, tokenId, amount/TOKENS_PER_ETH, data);
        }
    }

    function distribute(
        address payable _receiver,
        uint256 _tier,
        uint256 _amount
    ) external onlyOwner {
        BoxToken storage boxToken = boxTokenTiers[tokenTiers[_tier].boxToken];
        require(_amount != 0, "nothing to distribute");
        require(
            boxToken.funds - boxToken.distributed >= _amount,
            "exceeds balance"
        );
        boxToken.distributed += _amount;
        Address.sendValue(_receiver, _amount);
        emit FundsDistributed(_receiver, _tier, _amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getBoxTokens() public view returns (address[] memory boxTokens) {
        boxTokens = new address[](boxTokenCounter);
        for (uint8 i = 1; i <= boxTokenCounter; i++) {
            boxTokens[i - 1] = tokenTiers[i].boxToken;
        }
    }

    function allBalancesOf(address holder)
        external
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](boxTokenCounter);
        for (uint8 i; i < boxTokenCounter; i++) {
            balances[i] = balanceOf(holder, i);
        }
    }

    receive() external whenNotPaused payable {
        if (boxTokenTiers[msg.sender].id != 0) {
            boxTokenTiers[msg.sender].amount = IERC20(msg.sender).totalSupply();
            boxTokenTiers[msg.sender].funds += msg.value - (msg.value*fee/FEE_PRECISION);
            boxTokenTiers[address(0)].funds += (msg.value*fee/FEE_PRECISION);
        } else {
            bytes memory data;
            boxTokenTiers[address(0)].funds += msg.value;
            _mint(msg.sender, 0, msg.value, data);
        }
    }
}
