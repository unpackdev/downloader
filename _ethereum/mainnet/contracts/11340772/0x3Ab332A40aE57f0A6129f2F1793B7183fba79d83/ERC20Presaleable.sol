// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./RoleAware.sol";
import "./ERC20.sol";

abstract contract ERC20Presaleable is RoleAware, ReentrancyGuard, ERC20 {
    bool internal _presale = false;

    uint256 public presaleApePerEther = 200;
    uint256 public presaleApePerEtherAfterThreshhold = 180;
    uint256 public uniswapApePerEth = 160;
    uint256 public presaleEtherReceived = 0 ether;
    uint256 public maxPresaleEtherValue;


    uint256 internal _minTokenPurchaseAmount = .1 ether;
    uint256 internal _maxTokenPurchaseAmount = 1.5 ether;
    uint256 internal _presaleEtherThreshhold = 69 ether;

    mapping(address => bool) private _whitelisted;
    mapping(address => uint256) public presaleContributions;

    event PresalePurchased(address buyer, uint256 entitlement, uint256 weiContributed);

    constructor(uint256 maxPresaleValue) public {
        maxPresaleEtherValue = maxPresaleValue.mul(1 ether);
    }

    modifier onlyDuringPresale() {
        require(_presale == true || _whitelisted[msg.sender], "The presale is not active");
        _;
    }

    modifier onlyBeforePresale() {
        require(_presale == false);
        _;
    }

    function stopPresale() public onlyDeveloper onlyDuringPresale {
        _presale = false;
    }

    function startPresale() public onlyBeforeUniswap onlyDeveloper {
        _presale = true;
    }

    function addPresaleWhitelist(address buyer) public onlyBeforeUniswap onlyDeveloper {
        _whitelisted[buyer] = true;
    }

    function presale()
        public
        payable
        onlyDuringPresale
        nonReentrant
        returns (bool)
    {
        require(
            msg.value >= _minTokenPurchaseAmount,
            "Minimum purchase amount not met"
        );
        require(
            presaleEtherReceived.add(msg.value) <= maxPresaleEtherValue || _whitelisted[msg.sender],
            "Presale maximum already achieved"
        );
        require(
            presaleContributions[msg.sender].add(msg.value.mul(presaleApePerEtherAfterThreshhold)) <=
                _maxTokenPurchaseAmount.mul(presaleApePerEtherAfterThreshhold),
            "Amount of ether sent too high"
        );

        presaleContributions[msg.sender] = presaleContributions[msg.sender]
            .add(
            msg.value.mul(
                presaleEtherReceived > _presaleEtherThreshhold
                    ? presaleApePerEtherAfterThreshhold
                    : presaleApePerEther
            )
        );

        
        if (!_whitelisted[msg.sender]) {
            presaleEtherReceived = presaleEtherReceived.add(msg.value);
        }

        emit PresalePurchased(msg.sender, presaleContributions[msg.sender], msg.value);

        _developer.transfer(msg.value.mul(2).div(10));
    }

    function _getPresaleEntitlement() internal returns (uint256) {
        require(
            presaleContributions[msg.sender] >= 0,
            "No presale contribution or already redeemed"
        );
        uint256 value = presaleContributions[msg.sender];
        presaleContributions[msg.sender] = 0;
        return value;
    }

    // presale funds only claimable after uniswap pair created to prevent malicious 3rd-party listing
    function claimPresale()
        public
        onlyAfterUniswap
        nonReentrant
        returns (bool)
    {
        uint256 result = _getPresaleEntitlement();
        if (result > 0) {
            _mint(msg.sender, result);
        }
    }

}
