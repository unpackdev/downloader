//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Derpys.sol";

/*****
                                                    
▓█████▄ ▓█████  ██▀███   ██▓███ ▓██   ██▓           
▒██▀ ██▌▓█   ▀ ▓██ ▒ ██▒▓██░  ██▒▒██  ██▒           
░██   █▌▒███   ▓██ ░▄█ ▒▓██░ ██▓▒ ▒██ ██░           
░▓█▄   ▌▒▓█  ▄ ▒██▀▀█▄  ▒██▄█▓▒ ▒ ░ ▐██▓░           
░▒████▓ ░▒████▒░██▓ ▒██▒▒██▒ ░  ░ ░ ██▒▓░           
 ▒▒▓  ▒ ░░ ▒░ ░░ ▒▓ ░▒▓░▒▓▒░ ░  ░  ██▒▒▒            
 ░ ▒  ▒  ░ ░  ░  ░▒ ░ ▒░░▒ ░     ▓██ ░▒░            
 ░ ░  ░    ░     ░░   ░ ░░       ▒ ▒ ░░             
   ░       ░  ░   ░              ░ ░                
 ░                               ░ ░                
  ██████  ██▓███   ▒█████   ▒█████   ██ ▄█▀  ██████ 
▒██    ▒ ▓██░  ██▒▒██▒  ██▒▒██▒  ██▒ ██▄█▒ ▒██    ▒ 
░ ▓██▄   ▓██░ ██▓▒▒██░  ██▒▒██░  ██▒▓███▄░ ░ ▓██▄   
  ▒   ██▒▒██▄█▓▒ ▒▒██   ██░▒██   ██░▓██ █▄   ▒   ██▒
▒██████▒▒▒██▒ ░  ░░ ████▓▒░░ ████▓▒░▒██▒ █▄▒██████▒▒
▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░░ ▒░▒░▒░ ░ ▒░▒░▒░ ▒ ▒▒ ▓▒▒ ▒▓▒ ▒ ░
░ ░▒  ░ ░░▒ ░       ░ ▒ ▒░   ░ ▒ ▒░ ░ ░▒ ▒░░ ░▒  ░ ░
░  ░  ░  ░░       ░ ░ ░ ▒  ░ ░ ░ ▒  ░ ░░ ░ ░  ░  ░  
      ░               ░ ░      ░ ░  ░  ░         ░  
                                                    
*****/

/// @title DerpySpooks
/// @author @CoinFuPanda @DerpysNFT
/** 
 * @notice The DerpySpooks are undead and unsavoury Derpys
 * that have been banished from this realm. They can be summoned 
 * from beyond the Aether if the summoner is willing to pay 
 * the blood price. Summoning costs only a drop of Derpy blood,
 * but if the summoner does not hold a Derpy they can pay in Ether.
 */
contract DerpySpooks is ERC721, ERC721Enumerable, ERC721Pausable, ERC721Burnable, Ownable {
    address payable public derpysContract = payable(0xbC1E44dF6A4C09f87D4f2500c686c61429eeA112);
    bool public SUMMONING = true; 
	uint256 public MAX_SPOOKS = 3110;
    uint256 public AIRDROP_SPOOKS = 100;
    uint256 public BLOOD_PRICE = 0.02 ether;
	string private baseURI;

    /**
     * @param _baseTokenURI is the base address for metadata
     * */
	constructor (
        string memory _baseTokenURI
    ) 
        ERC721("DerpySpooks", "DSPOOK") 
    {
		setBaseURI(_baseTokenURI);
	}

    receive() external payable {
        //allow the contract to accept blood sacrifices
    }

    /**
     * @notice list the ids of all the DerpySpooks in _owner's wallet
     * @param _owner is the wallet address of the DerpySpook owner
     * */
    function listMyDerpys(address _owner) 
        external 
        view 
        returns (uint256[] memory) 
    {
        uint256 nSpooks = balanceOf(_owner);
        // if zero return an empty array
        if (nSpooks == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory spookList = new uint256[](nSpooks);
            uint256 ii;
            for (ii = 0; ii < nSpooks; ii++) {
                spookList[ii] = tokenOfOwnerByIndex(_owner, ii);
            }
            return spookList;
        }
    }

    /**
     * @notice SUMMON DERPYSPOOKS FROM BEYOND THE ETHER
     * @param numSpooks is the number of spooks to summon
     * */
    function summonDerpySpook(uint256 numSpooks) public payable {   
        require(
            SUMMONING == true, 
            "The dead may not be summoned at this time"
        );	
    	require(
            (numSpooks > 0) && (numSpooks <= 100),
            "You can summon between 1 and 100 spooks"
        );
    	require(
            (totalSupply() + numSpooks) <= MAX_SPOOKS,
            "There aren't that many DerpySpooks left"
        );
    	require(
            msg.value >= (bloodOrEther() * numSpooks),
            "The blood price offered is not enough"
        );

        //SUMMON THEM
    	uint256 iderp;
    	for(iderp = 0; iderp < numSpooks; iderp++) {
    		uint256 mintId = totalSupply();
    		_safeMint(msg.sender, mintId);
    	}
    }

    /**
     * @notice will the summoning be paid in blood or Ether?
     * @dev if the msg.sender holds a Derpy mints are free (BLOOD),
     * otherwise they cost ETHER
     * */
    function bloodOrEther() public view returns (uint256) {
        require(
            totalSupply() < MAX_SPOOKS,
            "No spooks remain unsummoned"
        );

        Derpys derpys = Derpys(derpysContract);
        uint256 ownerDerpys = derpys.balanceOf(msg.sender);

        if (ownerDerpys > 0) {
            //summoning paid in Derpy blood, no Ether required
            return 0;
        } else {
            //Ether is required in place of Derpy blood
            return BLOOD_PRICE;
        }
    }

    /**
     * @notice set a new metadata baseUri
     * @param baseURI_ is the new e.g. ipfs metadata root
     * */
    function setBaseURI(string memory baseURI_) public onlyOwner {
    	baseURI = baseURI_;
    }

    /**
     * @notice set a new price for summoning DerpySpooks
     * only payable for non Derpy holders
     * @param newWeiPrice is the new price in wei
     * */
    function setBloodPrice(uint256 newWeiPrice) public onlyOwner {
        BLOOD_PRICE = newWeiPrice;
    }

    /**
     * @notice point this contract to the Derpys contract to check 
     * if minters hold Derpys
     * @param newAddress is the new contract address of Derpys
     * */
    function setDerpysAddress(address payable newAddress) public onlyOwner {
        derpysContract = newAddress;
    }

    /**
     * @notice start or stop the summoning (minting)
     * */
    function flipSummoning() public onlyOwner {
    	SUMMONING = !SUMMONING;
    }

    /**
     * @dev pause all contract functions and token transfers
     * */
    function stopResurrection() public onlyOwner whenNotPaused {
    	_pause();
    }

    /**
     * @dev resume all contract functions and token transfers
     * */
    function startResurrection() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice reduce the total supply of the collection
     * @param newMax new supply limit for the collection
     * */
    function reduceSupply(uint256 newMax) public onlyOwner {
        require(
            (newMax < MAX_SPOOKS) && (newMax >= totalSupply()), 
            "the supply may only be reduced"
        );
        MAX_SPOOKS = newMax;
    }

    /**
     * @notice withdraw sacrificial offerings
     * */
    function withdrawBloodSacrifice() public payable onlyOwner {
    	payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice airdrop spooks to another wallet
     * */
    function airdropDerpySpooks(uint256 numSpooks, address receiver) public onlyOwner {
    	// 33 DerpySpooks are reserved for airdrops, giveaways and the legends who helped us build this. 
    	// Thanks xx
    	
        uint256 nextTokenId = totalSupply();

        require(
            numSpooks > 0, 
            "Positive integer Spooks only!"
        );
        require(
            (nextTokenId + numSpooks) <= MAX_SPOOKS, 
            "There are not enough Spooks left!"
        );
    	require(
            (AIRDROP_SPOOKS - numSpooks) >= 0,
            "Airdrop quota exceeded!"
        );
        uint256 iDerp;
    	for (iDerp = 0; iDerp < numSpooks; iDerp++) {
    		_safeMint(receiver, (nextTokenId + iDerp));
            AIRDROP_SPOOKS -= 1;
    	}
    }
    
    /**
     * @dev override _baseURI() method in ERC721.sol to return the base URI for our metadata
     * */
    function _baseURI() internal view virtual override returns (string memory) {
    	return baseURI;
    }

    /**
    * @dev override _beforeTokenTransfer in ERC721 contracts
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal 
    virtual 
    override(ERC721, ERC721Enumerable, ERC721Pausable) {
    	super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
    * @dev override supportsInterface in ERC721 contracts
    */
    function supportsInterface (bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns(bool) {
    	return super.supportsInterface(interfaceId);
    }

}