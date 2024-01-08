//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";


// Derpys is an ERC721 contract with the powers to catch Derpys! They are very
// preoccupied running around accumulating stuff, but you can entice them 
// with ETH and catch them. They need to be caught soon, before we are overrun!
// Enticement is denominated in ETH (/wei) and rises in Fibonnacci increments.
// Thank you for signing up for MISSION DERPY. GOOD LUCK OUT THERE.

// Big love to BGANPUNKSV2 - bastardganpunks.club 
// We've used your contract as a reference point for this :)

contract Derpys is ERC721, ERC721Enumerable, ERC721Pausable, Ownable {
	uint256 public constant MAX_DERPYS = 10000;
    uint256 public AIRDROP_DERPYS = 33;
    uint256 public LIMITED_EDERPTIONS = 0; //max is 111

	// Check the ipfs provenance hash here when all derpys are caught
	string public LEGIT_DERPY_HASH = "";

	// Be sure to store metadata at tokenURIs of baseURI/tokenId
	string private baseURI;

	constructor (string memory baseTokenURI) ERC721("Derpys", "DERP") {
		setBaseURI(baseTokenURI);
	}

    //get the next token id accounting for airdropped derps
    function currentSupply() public view returns (uint256) {
        return totalSupply() - LIMITED_EDERPTIONS;
    }

	// get the catch cost in wei for the next loose derpy
	function getCatchCost() public view returns (uint256) {
		require(currentSupply() < MAX_DERPYS, "This derpy does not exist! There are only 10,000");

		uint256 nextDerpy = currentSupply();

        //FIBONNAAACCIIIIIIIIIIIIII! :)
        if (nextDerpy >= 9900) {
            return 1000000000000000000;        // 9900-10000: 1.00 ETH
        } else if (nextDerpy >= 9500) {
            return  890000000000000000;         // 9500-9900: 0.89 ETH
        } else if (nextDerpy >= 9000) {
            return  550000000000000000;         // 9000-9500: 0.55 ETH
        } else if (nextDerpy >= 8500) {
            return  340000000000000000;         // 8500-9000: 0.34 ETH
        } else if (nextDerpy >= 7500) {
            return  210000000000000000;         // 7500-8500: 0.21 ETH
        } else if (nextDerpy >= 6000) {
            return  130000000000000000;         // 6000-7500: 0.13 ETH 
        } else if (nextDerpy >= 4000) {
            return   80000000000000000;         // 4000-6000: 0.08 ETH 
        } else if (nextDerpy >= 2000) {
            return   50000000000000000;         // 2000-4000: 0.05 ETH
        } else if (nextDerpy >= 1000) {
            return   30000000000000000;         // 1000-2000: 0.03 ETH
        } else {
            return   20000000000000000;         //    0-1000: 0.02 ETH
        }
    }

    function catchDerpy(uint256 numDerpys) public payable whenNotPaused {
    	// If you pay attention to this function, you'll see that you can purchase
    	// up to 50 Derpys at the same price. EVEN IF your purchase crosses into
    	// the next price tier. You lucky things ;)
    	
    	require(numDerpys > 0 && numDerpys <= 50, "You can catch between 1 and 50 derpys");
    	require(currentSupply() + numDerpys <= MAX_DERPYS, "There aren't that many Derpys left!");
    	require(msg.value >= (getCatchCost() * numDerpys), "The Ether value sent is less than the needed catch price!");

    	uint256 iderp;
    	for(iderp = 0; iderp < numDerpys; iderp++) {
    		uint256 mintId = currentSupply();
    		_safeMint(msg.sender, mintId);
    	}
    }

    //list all the derpys owned by owner_
    function listMyDerpys(address owner_) external view returns (uint256[] memory) {
    	uint256 nDerpys = balanceOf(owner_);
    	// if zero return an empty array
    	if (nDerpys == 0) {
            return new uint256[](0);
    	}
    	else {
    		uint256[] memory derpList = new uint256[](nDerpys);
    		uint256 ii;
    		for (ii = 0; ii < nDerpys; ii++) {
    			derpList[ii] = tokenOfOwnerByIndex(owner_, ii);
    		}
    		return derpList;
    	}
    }

    //set the ipfs hash
    function setProvenanceHash(string memory hash_) public onlyOwner {
    	LEGIT_DERPY_HASH = hash_;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
    	baseURI = baseURI_;
    }

    function startMission() public onlyOwner whenPaused {
    	require(bytes(baseURI).length > 0, "Metadata must be uploaded and its location must be set via setBaseURI()");
    	_unpause();
    }

    function stopMission() public onlyOwner whenNotPaused {
    	_pause();
    }

    function withdrawMissionBounty() public payable onlyOwner {
    	require(payable(msg.sender).send(address(this).balance));
    }

    function airdropDerpys(uint256 numDerpys, address receiver) public onlyOwner {
    	// 33 Derpys are reserved for airdrops and for the legends who helped us build this. 
    	// Thanks xx
    	
        uint256 nextTokenId = currentSupply();

        require(numDerpys > 0, "Positive integer Derpys onlY!");
        require((nextTokenId + numDerpys) <= MAX_DERPYS, "There are not enough Derpys left!");
    	require((AIRDROP_DERPYS - numDerpys) >= 0, "Airdrop quota exceeded!");
        uint256 iDerp;
    	for (iDerp = 0; iDerp < numDerpys; iDerp++) {
    		_safeMint(receiver, (nextTokenId + iDerp));
            AIRDROP_DERPYS -= 1;
    	}
    }

    function giveLtdDerpys(uint256 numDerpys, uint256 tokenId, address receiver) public onlyOwner {
        // 111 Limited edition Derpys are reserved for milestone airdrops
        // Ltd Derpys are at ids: 10000 <= id < 10111

        require(numDerpys > 0, "Positive integer Derpys only!");
        require((tokenId >= MAX_DERPYS) && (tokenId + numDerpys <= 10111), "Limited Ederptions are between: 10000 <= id < 10111");
        uint256 iDerp;
        for (iDerp = 0; iDerp < numDerpys; iDerp++) {
            _safeMint(receiver, (tokenId + iDerp));
            LIMITED_EDERPTIONS += 1;
        }
    }

    receive() external payable {
        //allow the contract to receive eth to buy dem derpys
    }
    
    //override _baseURI() method in ERC721.sol to return the base URI for our metadata
    function _baseURI() internal view virtual override returns (string memory) {
    	return baseURI;
    }

    //override inherited hooks and functions
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal 
    virtual 
    override(ERC721, ERC721Enumerable, ERC721Pausable) {
    	super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface (bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns(bool) {
    	return super.supportsInterface(interfaceId);
    }

    //test only functions, to get constants for checking
    function testGetBaseURI() public view returns (string memory) {
        return baseURI;
    }
}