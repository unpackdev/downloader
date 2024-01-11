// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

interface IOil {
    function allStakedOfStaker(address staker_)
        external
        view
        returns (uint256[] memory, uint256[] memory);
}

interface IMoonbirds {
    function balanceOf(address owner) external view returns (uint256);
}

contract Moonbibiz is ERC721A, Ownable {
    uint256 public constant PRICE = 0.0069 ether;
    uint256 public constant MAX_PER_TXN = 5;

    bool public publicSale = false;
    uint256 public maxSupply = 999;
    string private baseURI;

    IOil public immutable habibizContract;
    IMoonbirds public immutable moonbirdsContract;

    mapping(address => bool) public claimedFreeMint;

    constructor(IOil _habibizContract, IMoonbirds _moonbirdsContract)
        ERC721A("Moonbibiz", "MOONBIBIZ")
    {
        habibizContract = _habibizContract;
        moonbirdsContract = _moonbirdsContract;
    }

    modifier publicSaleOpen() {
        require(publicSale, "Public Sale Not Started");
        _;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    modifier insideLimits(uint256 _quantity) {
        require(totalSupply() + _quantity <= maxSupply, "Hit Limit");
        _;
    }

    modifier hasValue(uint256 _quantity) {
        require(msg.value >= PRICE * _quantity, "Not Enough Funds");
        _;
    }

    modifier insideMaxPerTxn(uint256 _quantity) {
        require(_quantity > 0 && _quantity <= MAX_PER_TXN, "Over Max Per Txn");
        _;
    }

    function mint(uint256 _quantity)
        public
        payable
        publicSaleOpen
        hasValue(_quantity)
        insideLimits(_quantity)
        insideMaxPerTxn(_quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    function hasClaimableAddress(address _address) public view returns (bool) {
        (uint256[] memory habibiz, uint256[] memory royals) = IOil(
            habibizContract
        ).allStakedOfStaker(_address);
        uint256 totalStakedHabibiz = habibiz.length + royals.length;
        return
            totalStakedHabibiz > 0 ||
            moonbirdsContract.balanceOf(_address) > 0;
    }

    function claim() public publicSaleOpen insideLimits(1) {
        require(
            hasClaimableAddress(msg.sender),
            "Must Own Moonbird OR Staked Habibiz"
        );
        require(!claimedFreeMint[msg.sender], "Already Claimed!");
        claimedFreeMint[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function adminMint(address _recipient, uint256 _quantity)
        public
        onlyOwner
        insideLimits(_quantity)
    {
        _safeMint(_recipient, _quantity);
    }

    function decreaseTotalSupply(uint256 _total) public onlyOwner {
        require(
            _total <= maxSupply && _total >= totalSupply(),
            "Can Only Decrease"
        );
        maxSupply = _total;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(
            payable(0x169F86544558aC4a1a6d90CE2F2a75F9c860A9C9),
            (balance * 50) / 100
        );
        Address.sendValue(
            payable(0xe617098816f6FDc2f4581CF8872C549e75CfA990),
            (balance * 50) / 100
        );
    }
}
