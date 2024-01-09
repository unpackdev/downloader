// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";

// ██╗    ██╗██╗  ██╗ ██████╗     ██╗███████╗    ▄▄███▄▄· █████╗ ███╗   ███╗ ██████╗ ████████╗    ██████╗
// ██║    ██║██║  ██║██╔═══██╗    ██║██╔════╝    ██╔════╝██╔══██╗████╗ ████║██╔═══██╗╚══██╔══╝    ╚════██╗
// ██║ █╗ ██║███████║██║   ██║    ██║███████╗    ███████╗███████║██╔████╔██║██║   ██║   ██║         ▄███╔╝
// ██║███╗██║██╔══██║██║   ██║    ██║╚════██║    ╚════██║██╔══██║██║╚██╔╝██║██║   ██║   ██║         ▀▀══╝
// ╚███╔███╔╝██║  ██║╚██████╔╝    ██║███████║    ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝   ██║         ██╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝╚══════╝    ╚═▀▀▀══╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝         ╚═╝

/**
 * @title Samot Token
 * SamotToken - a contract for the Samot Token
 */

abstract contract SamotNFT {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
}

contract SamotToken is ERC20, Ownable {
    using SafeMath for uint256;

    //addresses
    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    address constant WALLET2 = 0xD9CC8af4E8ac5Cb5e7DdFffD138A58Bac49dAEd5;
    address stakingAddress;
    address[] burnlistAddr;
    address[] claimlistAddr;

    //uint256
    uint256 public maxToMintPerNFT = 100;
    uint256 public maxToMint = 50000;
    uint256 public maxSupply = 5000000;
    uint256 public mintPrice = 200000000000000;
    uint256 multiplier = 2;

    //bools
    bool public preSaleIsActive = false;
    bool public saleIsActive = false;

    //contracts
    SamotNFT nft;

    //mappings
    mapping(address => bool) public burnlist;
    mapping(address => bool) public claimlist;

    //constructor
    constructor(
        string memory _name,
        string memory _symbol,
        address _nftAddress
    ) ERC20(_name, _symbol) {
        nft = SamotNFT(_nftAddress);
    }

    //modifiers
    modifier onlyBurnersOrOwner() {
        require(
            isBurnlisted(msg.sender) || owner() == _msgSender(),
            "Only callable by Burner Contract or Owner"
        );
        _;
    }

    modifier onlyClaimersOrOwner() {
        require(
            isClaimlisted(msg.sender) || owner() == _msgSender(),
            "Only callable by Claimer Contract or Owner"
        );
        _;
    }

    //Burnlist logic
    function addAddressToBurnlist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        require(!isBurnlisted(addr), "Already burnlisted");
        burnlist[addr] = true;
        success = true;
    }

    function addAddressesToBurnlist(address[] memory addrs)
        public
        onlyOwner
        returns (bool success)
    {
        burnlistAddr = addrs;
        for (uint256 i = 0; i < burnlistAddr.length; i++) {
            addAddressToBurnlist(burnlistAddr[i]);
        }
        success = true;
    }

    function isBurnlisted(address addr)
        public
        view
        returns (bool isBurnListed)
    {
        return burnlist[addr];
    }

    function removeAddressFromBurnlist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        require(isBurnlisted(addr), "Not burnlisted");
        burnlist[addr] = false;
        success = true;
    }

    //Claimlist logic
    function addAddressToClaimlist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        require(!isClaimlisted(addr), "Already claimlisted");
        claimlist[addr] = true;
        success = true;
    }

    function addAddressesToClaimlist(address[] memory addrs)
        public
        onlyOwner
        returns (bool success)
    {
        claimlistAddr = addrs;
        for (uint256 i = 0; i < claimlistAddr.length; i++) {
            addAddressToClaimlist(claimlistAddr[i]);
        }
        success = true;
    }

    function isClaimlisted(address addr)
        public
        view
        returns (bool isClaimListed)
    {
        return claimlist[addr];
    }

    function removeAddressFromClaimlist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        require(isClaimlisted(addr), "Not claimlisted");
        claimlist[addr] = false;
        success = true;
    }

    // Burn function
    function burn(address _from, uint256 _amount) external onlyBurnersOrOwner {
        _burn(_from, _amount);
    }

    // Claim function
    function claim(address _claimer, uint256 _reward)
        external
        onlyClaimersOrOwner
    {
        require(
            ((totalSupply().add(_reward)).div(10**18)) <= maxSupply,
            "Exceeds token limit."
        );
        _mint(_claimer, _reward);
    }

    // Set functions
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function setStakingContract(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    function setNFTContract(address _nftAddress) external onlyOwner {
        nft = SamotNFT(_nftAddress);
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxToMint(uint256 _maxToMint) external onlyOwner {
        maxToMint = _maxToMint;
    }

    function setMaxToMintPerNFT(uint256 _maxToMint) external onlyOwner {
        maxToMintPerNFT = _maxToMint;
    }

    function setMultiplier(uint256 _multiplier) external onlyOwner {
        multiplier = _multiplier;
    }

    // Get price function
    function getPrice() public view returns (uint256) {
        uint256 currentSupply = totalSupply().div(10**18);
        require(currentSupply <= maxSupply, "Sold out.");
        if (currentSupply >= 4000000) {
            return mintPrice.mul(multiplier**3);
        } else if (currentSupply >= 3000000) {
            return mintPrice.mul(multiplier**2);
        } else if (currentSupply >= 2000000) {
            return mintPrice.mul(multiplier);
        } else {
            return mintPrice;
        }
    }

    // Minting function
    function mint(uint256 numberOfTokens) public payable {
        uint256 currentSupply = totalSupply().div(10**18);
        require(saleIsActive, "Sale is not active.");
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        require(
            currentSupply.add(numberOfTokens) <= maxSupply,
            "Exceeds token limit."
        );
        uint256 balance = balanceOf(msg.sender).div(10**18);
        if (preSaleIsActive) {
            require(
                getPrice().mul(numberOfTokens) <= msg.value,
                "ETH sent is incorrect."
            );
            require(
                nft.balanceOf(msg.sender) > 0,
                "You must own at least one Samot NFT to participate in the pre-sale."
            );
            require(
                numberOfTokens <=
                    maxToMintPerNFT.mul(nft.balanceOf(msg.sender)),
                "Exceeds limit for pre-sale."
            );
            require(
                balance.add(numberOfTokens) <=
                    maxToMintPerNFT.mul(nft.balanceOf(msg.sender)),
                "Exceeds limit for pre-sale."
            );
        } else {
            require(
                getPrice().mul(numberOfTokens) <= msg.value,
                "ETH sent is incorrect."
            );
            require(
                numberOfTokens <= maxToMint,
                "Exceeds limit for public sale."
            );
            require(balance <= maxToMint, "Exceeds limit for public sale.");
        }
        _mint(msg.sender, numberOfTokens.mul(10**18));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 wallet1Balance = balance.mul(10).div(100);
        uint256 wallet2Balance = balance.mul(85).div(100);
        payable(WALLET1).transfer(wallet1Balance);
        payable(WALLET2).transfer(wallet2Balance);
        payable(msg.sender).transfer(
            balance.sub(wallet1Balance.add(wallet2Balance))
        );
    }
}
