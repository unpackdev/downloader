// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";


contract GeniusTokens is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // modify token name
    string private constant NAME = "Genius Tokens";
    // modify token symbol
    string private constant SYMBOL = "GNUS";
    uint256 public constant DECIMALS = 10 ** 18;
    // ICO data
    uint256 public GNUSSoldTokens = 0;
    uint256 public weiReceived = 0;
    bool ITOisPaused = false;
    uint256[] public rates = [1000, 800, 640, 512];
    uint256[] public stageEndsAtWei = [12500 * DECIMALS, 25000 * DECIMALS, 37500 * DECIMALS, 50000 * DECIMALS];
    uint8 internal stage = 0;
    uint256 public constant INIT_SUPPLY = 7380000 * DECIMALS;  // 7.38 million tokens
    uint256 public constant ICO_SUPPLY = 36900000 * DECIMALS;  // 36.9 million tokens
    uint256 public constant MAX_SUPPLY = 50000000 * DECIMALS;  // 50 million tokens
    address public superAdmin;

    constructor () ERC20(NAME, SYMBOL) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        superAdmin = msg.sender;
        mint(msg.sender, INIT_SUPPLY);
    }

    modifier onlyAdmin()
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins.");
        _;
    }

    modifier onlyMinter()
    {
        require(hasRole(MINTER_ROLE, msg.sender), "Restricted to minters.");
        _;
    }

    function mint(address to, uint256 amount) public virtual onlyMinter {
        require(totalSupply() + amount <= MAX_SUPPLY, "Minting would exceed max supply");
        _mint(to, amount);
    }

    function addMinter(address minter) public virtual onlyAdmin {
        grantRole(MINTER_ROLE, minter);
    }

    function removeMinter(address account) public virtual onlyAdmin {
        revokeRole(MINTER_ROLE, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(!(hasRole(DEFAULT_ADMIN_ROLE, account) && (superAdmin == account)), "Cannot renounce superAdmin from Admin Role");
        super.renounceRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyAdmin {
        require(!(hasRole(DEFAULT_ADMIN_ROLE, account) && (superAdmin == account)), "Cannot revoke superAdmin from Admin Role");
        super.revokeRole(role, account);
    }

    function GNUSBalance() public view returns(uint256) {
        return GNUSSoldTokens;
    }

    function ETHBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function WEIReceived() public view returns(uint256) {
        return weiReceived;
    }

    // owner can withdraw eth to any address
    function withdrawETH(address _address, uint256 _amount)  public virtual onlyAdmin {
        require(_amount <= ETHBalance(), "Not enough eth balance");
        address payable to = payable(_address);
        to.transfer(_amount);
    }

    // pause the Token offering
    function pauseITO(bool pause) public virtual onlyAdmin {
        ITOisPaused = pause;
    }

    // Detect receiving eth
    receive () external payable {
        // Check GNUS token before receive ETH
        require(msg.value > 0, "You have sent 0 ether!");
        require(!ITOisPaused, "ITO is currently paused!");
        uint256 tokenAmount = calcTokenAmount(msg.value);
        _mint(address(msg.sender), tokenAmount);
    }

    // this is the function to scale the ICO with early adopters getting better deals.
    function calcTokenAmount(uint256 weiAmount) internal returns(uint256) {
        uint256 curWeiReceived = weiReceived;
        uint256 remainingWeiAmount = weiAmount;
        uint256 GNUSTokenAmount = 0;
        uint8 curStage = stage;
        while ((remainingWeiAmount != 0) && (curStage < stageEndsAtWei.length)) {
            uint256 weiLeftInStage = stageEndsAtWei[curStage] - curWeiReceived;
            uint256 WeiToUse = (weiLeftInStage <  remainingWeiAmount) ? weiLeftInStage : remainingWeiAmount;
            GNUSTokenAmount += (WeiToUse * rates[curStage]);
            remainingWeiAmount -= WeiToUse;
            curWeiReceived += WeiToUse;
            if (remainingWeiAmount != 0) {
                curStage++;
            }
    }

    require(remainingWeiAmount == 0, 'To Much Ethereum Sent');
    require(GNUSSoldTokens + GNUSTokenAmount <= ICO_SUPPLY, "GNUS Tokens: cap exceeded");
    require(totalSupply() + GNUSTokenAmount <= MAX_SUPPLY, "Minting would exceed max supply");
    stage = curStage;
    weiReceived = curWeiReceived;
    GNUSSoldTokens += GNUSTokenAmount;
    return GNUSTokenAmount;
    }
}
