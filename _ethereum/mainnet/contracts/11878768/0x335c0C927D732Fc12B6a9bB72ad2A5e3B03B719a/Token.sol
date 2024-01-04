// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20Upgradeable.sol";
import "./ITokenDistributor.sol";
import "./ITransferLimiter.sol";
import "./IToken.sol";

contract Token is ERC20Upgradeable, IToken {
    uint256 public constant BURN_PERCENT = 5;

    address private distributor;
    address private treasury;
    address private transferLimiter;
    address private uniswapPair;
    bool private isLocked;
    mapping(address => bool) nonBurnableSenders;
    mapping(address => bool) nonBurnableRecipients;

    function initialize(
        string memory _name,
        string memory _symbol,
        address _distributor,
        address _treasury,
        address _transferLimiter,
        address _rcFarm,
        address _rcEthFarm
    ) public initializer {
        __Token_init(_name, _symbol, _distributor, _treasury, _transferLimiter, _rcFarm, _rcEthFarm);
    }

    function __Token_init(
        string memory _name,
        string memory _symbol,
        address _distributor,
        address _treasury,
        address _transferLimiter,
        address _rcFarm,
        address _rcEthFarm
    ) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(_name, _symbol);
        __Token_init_unchained(_distributor, _treasury, _transferLimiter, _rcFarm, _rcEthFarm);
    }

    function __Token_init_unchained(
        address _distributor,
        address _treasury,
        address _transferLimiter,
        address _rcFarm,
        address _rcEthFarm
    ) internal initializer {
        distributor = _distributor;
        treasury = _treasury;
        transferLimiter = _transferLimiter;
        isLocked = true;

        nonBurnableSenders[_distributor] = true;
        nonBurnableRecipients[_distributor] = true;
        nonBurnableSenders[_treasury] = true;
        nonBurnableRecipients[_treasury] = true;
        nonBurnableSenders[_rcFarm] = true;
        nonBurnableRecipients[_rcFarm] = true;
        nonBurnableSenders[_rcEthFarm] = true;
        nonBurnableRecipients[_rcEthFarm] = true;

        uint256 mintAmount = ITokenDistributor(distributor).getMaxSupply();
        _mint(distributor, mintAmount);
    }

    modifier tokensTransferable(address _from, address _to) {
        require(!isLocked || _from == distributor || _to == distributor, "Tokens are not transferable.");
        _;
    }

    modifier transferableAmount(address _to, uint256 _amount) {
        // sell transfer
        if (_to == uniswapPair) {
            uint256 transferLimitPerETH = ITransferLimiter(transferLimiter).getTransferLimitPerETH();
            if (transferLimitPerETH > 0) {
                // set transfer limit to amount of tokens for .5ETH
                uint256 transferLimit = transferLimitPerETH.div(2);
                require(_amount <= transferLimit, "Transfer amount is too big.");
            }
        }
        _;
    }

    modifier onlyDistributor() {
        require(msg.sender == distributor, "Only distributor allowed.");
        _;
    }

    modifier uniswapPairNotSet() {
        require(uniswapPair == address(0), "Uniswap pair is already set.");
        _;
    }

    function uniswapPairAddress() external view override returns (address) {
        return uniswapPair;
    }

    function setUniswapPair(address _uniswapPair) external override uniswapPairNotSet {
        uniswapPair = _uniswapPair;
        nonBurnableSenders[uniswapPair] = true;
    }

    function burnDistributorTokensAndUnlock() external override onlyDistributor {
        uint256 burnAmount = balanceOf(distributor);
        _burn(distributor, burnAmount);
        isLocked = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override tokensTransferable(from, to) transferableAmount(to, amount) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        bool shouldBurnTokens = !nonBurnableSenders[sender] && !nonBurnableRecipients[recipient];
        if (shouldBurnTokens) {
            uint256 burnAmount = amount.mul(BURN_PERCENT).div(100);
            super._transfer(sender, treasury, burnAmount);
            amount = amount.sub(burnAmount);
        }
        super._transfer(sender, recipient, amount);
    }

    uint256[43] private __gap;
}
