// SPDX-License-Identifier: MIT
// Made by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.11;

/**
  _____  _____  _____        _       _____    _____         _      ______ 
 |  __ \|  __ \|  __ \ /\   | |     / ____|  / ____|  /\   | |    |  ____|
 | |__) | |__) | |__) /  \  | |    | (___   | (___   /  \  | |    | |__   
 |  ___/|  ___/|  ___/ /\ \ | |     \___ \   \___ \ / /\ \ | |    |  __|  
 | |    | |    | |  / ____ \| |____ ____) |  ____) / ____ \| |____| |____ 
 |_|    |_|    |_| /_/    \_\______|_____/  |_____/_/    \_\______|______|
                                                                                                                                                    
 */

import "./Ownable.sol";
import "./IERC20.sol"; 

contract IPPPals {
    /** ERC-721 INTERFACE */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** CUSTOM INTERFACE */
    function mintTo(uint256 amount, address _to) external {}
}

abstract contract IBAMBOO is IERC20 {
    function burn(address _from, uint256 _amount) external {}
}

contract PPPalsSales is Ownable {
    IPPPals public pppals;

    /** MINT OPTIONS */
    uint256 public maxSupply = 6363;
    uint256 public maxPPPalsPerWallet = 20;
    uint256 public minted = 0;

    /** FLAGS */
    bool public isFrozen = false;
    bool public isSaleOpen = false;

    /** MAPPINGS  */
    mapping(address => uint256) public mintsPerAddress;

    /** BAMBOO */
    IBAMBOO public BAMBOO;
    uint256 public BAMBOOPrice = 250 * 10**18;

    /** MODIFIERS */
    modifier notFrozen() {
        require(!isFrozen, "CONTRACT FROZEN");
        _;
    }

    modifier checkMintBAMBOO(uint256 amount) {
        require(isSaleOpen, "SALE CLOSED");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(amount + mintsPerAddress[msg.sender] <= maxPPPalsPerWallet, "CANNOT MINT MORE THAN 20 PPPALS");
        require(minted + amount <= maxSupply, "MAX PPPALS MINTED");
        require(BAMBOO.balanceOf(msg.sender) >= BAMBOOPrice * amount, "NOT ENOUGH $BAMBOO TO BURN");
        _;
    }

    constructor(
        address _pppalsaddress,
        address _BAMBOOAddress
    ) Ownable() {
        pppals = IPPPals(_pppalsaddress);
        BAMBOO = IBAMBOO(_BAMBOOAddress);
    }
 
    function mintWithBAMBOO(uint256 amount) external checkMintBAMBOO(amount) {
        minted = minted + amount;
        mintsPerAddress[_msgSender()] = mintsPerAddress[_msgSender()] + amount;
        BAMBOO.burn(msg.sender, BAMBOOPrice * amount);
        pppals.mintTo(amount, _msgSender());
    }

    /** OWNER */

    function freezeContract() external onlyOwner {
        isFrozen = true;
    }

    function setPPPals(address _pppalsAddress) external onlyOwner notFrozen {
        pppals = IPPPals(_pppalsAddress);
    }

    function setBAMBOO(address _BAMBOOAddress) external onlyOwner notFrozen {
        BAMBOO = IBAMBOO(_BAMBOOAddress);
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner notFrozen {
        maxSupply = newMaxSupply;
    }

    function setMaxMintesPerWallet(uint256 newMaxPerWallet) external onlyOwner notFrozen {
        maxPPPalsPerWallet = newMaxPerWallet;
    }

    function setBAMBOOPrice(uint256 newMintPrice) external onlyOwner notFrozen {
        BAMBOOPrice = newMintPrice;
    }  

    function setSaleStatus(bool newStatus) external onlyOwner notFrozen {
        isSaleOpen = newStatus;
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawAllBAMBOO() external onlyOwner {
        BAMBOO.transfer(owner(), BAMBOO.balanceOf(owner()));
    }
}