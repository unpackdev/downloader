pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IVNFT {
    function fatality(uint256 _deadId, uint256 _tokenId) external;
    function buyAccesory(uint256 nftId, uint256 itemId) external;
    function claimMiningRewards(uint256 nftId) external;
    function addCareTaker(uint256 _tokenId, address _careTaker) external;
    function careTaker(uint256 _tokenId, address _user)
        external
        view
        returns (address _careTaker);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function itemPrice(uint256 itemId) external view returns (uint256 _amount);
}

contract NiftyTools {

    IVNFT public vnft;
    IERC20 public muse;
    address public owner;
    bool public paused;

    constructor(IVNFT _vnft, IERC20 _muse) public {
        vnft = _vnft;
        muse = _muse;
        owner = msg.sender;
    }

    modifier notPaused() {
        require(!paused, "PAUSED");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call");
        _;
    }

    function claimMultiple(uint256[] calldata ids) external notPaused onlyOwner {

        for (uint256 i = 0; i < ids.length; i++) {
            vnft.claimMiningRewards(ids[i]);
        }
        require(muse.transfer(msg.sender, muse.balanceOf(address(this))));
    }

    function feedMultiple(uint museCost, uint256[] calldata ids, uint256[] calldata itemIds)
        external
        notPaused
    {
        require(
            muse.transferFrom(msg.sender, address(this), museCost),
            "MUSE:Items"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            vnft.buyAccesory(ids[i], itemIds[i]);
        }
    }

    function setVNFT(IVNFT _vnft) public onlyOwner {
        vnft = _vnft;
    }

    function setPause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function approveContractMax() public onlyOwner {
        uint256 MAX_UINT256 = ~uint256(0);
        require(muse.approve(address(vnft), MAX_UINT256), "MUSE:approve");
    }
}