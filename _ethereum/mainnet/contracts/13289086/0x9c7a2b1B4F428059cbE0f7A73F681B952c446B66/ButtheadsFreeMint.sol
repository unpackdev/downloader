pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC721Holder.sol";

abstract contract BH {
    function mintButt(uint256 _numberOfButts) external payable virtual;

    function buttsOfOwner(address _owner)
        external
        view
        virtual
        returns (uint256[] memory);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;
}

contract BHFreeMint is ERC721Holder, Ownable {
    BH private butts;
    address wallet = 0x8a8320ceb5D99b6BB5B3967f40f422E471BeD72B;

    uint256 public _mintPrice = 0.06 ether;
    uint256 public startTimeSale = 0;
    bool public _freeMintActive = false;

    mapping(address => bool) private _freeMintList;
    mapping(address => uint256) private _freeMintListClaimed;
    mapping(address => uint256) private _freeMintAllowed;

    constructor(address dependedContract) {
        butts = BH(dependedContract);
    }

    //modifiers
    modifier onlyFreeMinters() {
        require(
            _freeMintList[_msgSender()],
            "You are not on the free mint list"
        );
        _;
    }

    function addToFreeList(
        address[] calldata addresses,
        uint256[] calldata allowed
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Address can not be null");

            _freeMintList[addresses[i]] = true;

            _freeMintListClaimed[addresses[i]] > 0
                ? _freeMintListClaimed[addresses[i]]
                : 0;

            _freeMintAllowed[addresses[i]] = allowed[i];
        }
    }

    function setStartTimeSale(uint256 _startSale) external onlyOwner {
        startTimeSale = _startSale;
    }

    function setPrice(uint256 _price) external onlyOwner {
        _mintPrice = _price;
    }

    function onFreeMintList(address addr) external view returns (bool) {
        return _freeMintList[addr];
    }

    function freeMintsLeft(address addr) external view returns (uint256) {
        return
            _freeMintList[addr]
                ? _freeMintAllowed[addr] - _freeMintListClaimed[addr]
                : 0;
    }

    function setFreeMintState(bool val) external onlyOwner {
        _freeMintActive = val;
    }

    function removeFromFreeMintList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Address can not be null");
            _freeMintList[addresses[i]] = false;
        }
    }

    function _mint(address _to, uint256 _butts) internal {
        require(
            address(this).balance >= _mintPrice * _butts,
            "Not enough money in the contract"
        );
        butts.mintButt{value: _mintPrice * _butts}(_butts);
        uint256[] memory booties = butts.buttsOfOwner(address(this));
        for (uint256 i = 0; i < _butts; i++) {
            butts.transferFrom(address(this), _to, booties[i]);
        }
    }

    function gift(address _to, uint256 _butts) external onlyOwner {
        _mint(_to, _butts);
    }

    function giftMany(address[] calldata _to, uint256[] calldata _butts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _butts.length; i++) {
            _mint(_to[i], _butts[i]);
        }
    }

    function freeMint(uint256 _numberOfButts) external onlyFreeMinters {
        require(_freeMintActive, "Free Mint is not active");
        require(block.timestamp >= startTimeSale, "Free Mint did not start yet");
        require(
            _freeMintListClaimed[_msgSender()] + _numberOfButts <=
                _freeMintAllowed[_msgSender()],
            "Purchase exceeds max allowed"
        );

        _freeMintListClaimed[_msgSender()] += _numberOfButts;
        _mint(_msgSender(), _numberOfButts);
    }

    function withdraw() public onlyOwner {
        uint256 _amount = address(this).balance;
        require(payable(wallet).send(_amount));
    }

    fallback() external payable {}

    receive() external payable {}
}
