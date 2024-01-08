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

contract SamotTokenF is ERC20, Ownable {
    using SafeMath for uint256;
    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    address constant WALLET2 = 0xD9CC8af4E8ac5Cb5e7DdFffD138A58Bac49dAEd5;
    address stakingAddress;
    uint256 public maxToMintPerNFT = 100;
    uint256 public maxToMint = 50000;
    uint256 public maxSupply = 6000000;
    bool public preSaleIsActive = true;
    bool public saleIsActive = false;
    uint256 public mintPrice = 200000000000000;
    uint256 initialSupply = 1000000;
    SamotNFT nft;

    constructor(
        string memory _name,
        string memory _symbol,
        address _contractAddress
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, initialSupply.mul(10**18));
        nft = SamotNFT(_contractAddress);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function setStakingContract(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    function setNFTContract(address _contractAddress) external onlyOwner {
        nft = SamotNFT(_contractAddress);
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

    function getPrice() public view returns (uint256) {
        uint256 currentSupply = totalSupply().div(10**18);
        require(currentSupply <= maxSupply, "Sold out.");
        if (currentSupply >= 5000000) {
            return mintPrice.mul(2**4);
        } else if (currentSupply >= 4000000) {
            return mintPrice.mul(2**3);
        } else if (currentSupply >= 3000000) {
            return mintPrice.mul(2**2);
        } else if (currentSupply >= 2000000) {
            return mintPrice.mul(2);
        } else {
            return mintPrice;
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active.");
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
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

    modifier onlyVaultorOwner() {
        require(
            msg.sender == stakingAddress || owner() == _msgSender(),
            "Only callable by Staking contract or Owner"
        );
        _;
    }

    function claim(address _claimer, uint256 _reward)
        external
        onlyVaultorOwner
    {
        _mint(_claimer, _reward);
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
