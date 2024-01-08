// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./YellowFunkie_CryptoBrotherhood.sol";
import "./YellowFunkie_CryptoBrotherhoodLootBox.sol";

contract YellowFunkie_CryptoBrotherhoodFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    address public lootBoxNftAddress = address(0);
    string private baseMetadataURI = "https://pygoogle-xno2aym5xq-nw.a.run.app/";
	string private nameContract = "YellowFunkie_CryptoBrotherhoodItemSale";

    /*
     * Enforce the existence of only 200000
     */
	uint256 public constant CREATURE_MAX_SUPPLY = 40000;
    uint256 public constant FACTORY_MAX_SUPPLY = 20000; 
	uint256 public factoryProduced = 0;
	uint256 private itemsPerLootbox = 0;
	YellowFunkie_CryptoBrotherhoodLootBox YellowFunkieLootBox;
	YellowFunkie_CryptoBrotherhood YellowFunkie;

    /*
     * Three different options for minting Creatures (basic, premium, and gold).
     */
    uint256 NUM_OPTIONS = 2;
    uint256 SINGLE_CREATURE_OPTION = 0;
    uint256 MULTIPLE_CREATURE_OPTION = 1;
    uint256 LOOTBOX_OPTION = 2;
    uint256 NUM_CREATURES_IN_MULTIPLE_CREATURE_OPTION = 4;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
		
		YellowFunkie = YellowFunkie_CryptoBrotherhood(nftAddress);

        fireTransferEvents(address(0), owner());
    }

	  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
	function setBaseMetadataURI(string memory _newBaseMetadataURI) external onlyOwner {
		baseMetadataURI = _newBaseMetadataURI;
	}
	function getBaseMetadataURI() external view onlyOwner returns(string memory){
		return baseMetadataURI;
	}
	function getFactoryProduced() external view onlyOwner returns(uint256){
		return factoryProduced;
	}
    function name() override external view returns (string memory) {
        return nameContract;
    }

    function symbol() override external pure returns (string memory) {
        return "YFCB";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override external view returns (uint256) {
        return NUM_OPTIONS;
    }
	
	function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, "contract/", nameContract));
    }
	function addLootBoxSupport(address _lootBoxNftAddress) public onlyOwner {
		lootBoxNftAddress = _lootBoxNftAddress;
		YellowFunkieLootBox = YellowFunkie_CryptoBrotherhoodLootBox(lootBoxNftAddress);

		emit Transfer(address(0), owner(), NUM_OPTIONS);
		NUM_OPTIONS = 3;
		itemsPerLootbox = YellowFunkieLootBox.itemsPerLootbox();
	}
	/*function mainContractGiveOwnership() public onlyOwner {
		YellowFunkie_CryptoBrotherhood YellowFunkie = YellowFunkie_CryptoBrotherhood(nftAddress);
		YellowFunkie.transferOwnership(owner());
        fireTransferEvents(nftAddress, owner());
    }
	
	function lootboxContractGiveOwnership() public onlyOwner {
		YellowFunkie_CryptoBrotherhoodLootBox YellowFunkieLootBox = YellowFunkie_CryptoBrotherhoodLootBox(lootBoxNftAddress);
		YellowFunkieLootBox.transferOwnership(owner());
        fireTransferEvents(lootBoxNftAddress, owner());
    }*/
	
    function transferOwnership(address newOwner) override public onlyOwner   {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

	function mint_unbox(address _toAddress)  public {
        // Must be sent from the owner proxy or owner.
        require((_msgSender() == lootBoxNftAddress), "Wrong owner" );
		
        //items already allocated for the lootbox, won't call canMint                 
		
		for (uint256 i = 0;i < itemsPerLootbox; i++) {
                YellowFunkie.factoryMintNFT(_toAddress);
            }
       
    }

    function mint(uint256 _optionId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        require(
				((address(proxyRegistry.proxies(owner())) == _msgSender()) ||
                (owner() == _msgSender())), 
			"Wrong owner"
        );
        require(canMint(_optionId), "Can't mint this option");
		
        if (_optionId == SINGLE_CREATURE_OPTION) {
			factoryProduced = factoryProduced + 1;
            YellowFunkie.factoryMintNFT(_toAddress);
        } else if (_optionId == MULTIPLE_CREATURE_OPTION) {
			factoryProduced = factoryProduced + NUM_CREATURES_IN_MULTIPLE_CREATURE_OPTION;
            for (
                uint256 i = 0;
                i < NUM_CREATURES_IN_MULTIPLE_CREATURE_OPTION;
                i++
            ) {
                YellowFunkie.factoryMintNFT(_toAddress);
            }
        } else if (_optionId == LOOTBOX_OPTION) {
			factoryProduced = factoryProduced + itemsPerLootbox;
            YellowFunkieLootBox.factoryMintNFT(_toAddress);
        }
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        
		
		require (_optionId < NUM_OPTIONS, "Invlaid option set"); 
		require (factoryProduced < FACTORY_MAX_SUPPLY,  "Can't mint anymore through the factory");
		
		uint256 creatureSupply;
		if (lootBoxNftAddress != address(0)) {
			//reserve space also for the lootboxes that were not open
			creatureSupply = YellowFunkie.totalSupply() + itemsPerLootbox * YellowFunkieLootBox.totalSupply();
		} else {
			creatureSupply = YellowFunkie.totalSupply();
		}

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_CREATURE_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == MULTIPLE_CREATURE_OPTION) {
            numItemsAllocated = NUM_CREATURES_IN_MULTIPLE_CREATURE_OPTION;
        } else if (_optionId == LOOTBOX_OPTION) {
            numItemsAllocated = itemsPerLootbox;
        }
        return (creatureSupply + numItemsAllocated <= (CREATURE_MAX_SUPPLY)) && (factoryProduced + numItemsAllocated <= FACTORY_MAX_SUPPLY);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI,"api/factory/", Strings.toString(_optionId)));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}
