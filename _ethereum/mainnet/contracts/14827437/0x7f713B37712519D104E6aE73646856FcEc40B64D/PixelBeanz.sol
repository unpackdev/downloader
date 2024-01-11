// SPDX-License-Identifier: MIT                                                                            
                                                                                        
//           ██                                                        
//       ████▒▒██                                                      
//     ██▒▒██▒▒██                                                      
//       ████▒▒██    ░░                                                
//         ██▒▒██████                                                  
//       ██▒▒▒▒██▒▒▓▓██                                                
//     ██▒▒▒▒▒▒▒▒██░░▓▓██                                              
//   ██▒▒▒▒▒▒░░░░██░░░░▒▒██████                                        
//   ██▒▒▒▒░░░░░░▒▒██░░▒▒▒▒▒▒▒▒██                                      
//   ██▒▒▒▒░░░░░░▒▒██░░▒▒▒▒░░░░▒▒████████████████                      
//   ██▒▒▒▒░░░░▒▒▒▒██▒▒▒▒░░░░░░▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒██                    
//   ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▒▒░░░░░░▒▒▒▒░░░░░░▒▒▒▒▒▒██                      
//     ████▒▒▒▒▒▒░░░░▒▒██░░░░░░▒▒▒▒░░░░▒▒▒▒▒▒██                        
//         ██▒▒░░░░░░▒▒████▒▒▒▒▒▒▒▒░░░░▒▒▒▒██                          
//         ██▒▒░░░░░░▒▒██  ██▒▒▒▒▒▒▒▒▒▒▒▒██                            
//         ██▒▒▒▒░░░░▒▒▒▒██  ████████████                              
//           ██▒▒▒▒▒▒▒▒░░░░████                                        
//           ██▒▒▒▒▒▒░░░░░░▒▒▒▒██                                      
//             ██▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒██                                    
//               ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██                                  
//                 ████▒▒▒▒▒▒▒▒████                                    
//                     ████████                                        
																	
															
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract PixelBeanz is ERC721A, Ownable {
	using Strings for uint;

	uint public MINT_PRICE = 0.0169 ether;
	uint public constant MAX_NFT_PER_TRAN = 20;
	address private immutable JAR;
	uint public maxSupply = 5000;

	bool public isPaused;
    bool public isMetadataFinal;
    string private _baseURL;
	string public prerevealURL = 'ipfs://QmdSfuCFzTnYuQbPEL9NSY8SxMYZarBt72TANxMZ8JTrFY';
	mapping(address => uint) private _walletMintedCount;

	constructor(address jar)
	ERC721A('PixelBeanz', 'BEANZ') {
        JAR = jar;
    }

	function contractURI() public pure returns (string memory) {
		return "ipfs://QmTWF4k5rMmDemwmAaHz2w7QTD9vXjbcq662BaBCJMuhkc";
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function reveal(string memory url) external onlyOwner {
        require(!isMetadataFinal, "PixelBeanz: Metadata is finalized");
		_baseURL = url;
	}

    function finalizeMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

    function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

	function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

	function setPrice(uint value) external onlyOwner {
		MINT_PRICE = value;
	}

	function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'PixelBeanz: No beanz');
		payable(JAR).transfer(balance);
	}

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			'PixelBeanz: Exceeds jar size'
		);
		_safeMint(to, count);
	}

	function setSupply(uint newMaxSupply) external onlyOwner {
		maxSupply = newMaxSupply;
	}

	function tokenURI(uint tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : prerevealURL;
	}

	function mint(uint count) external payable {
		require(!isPaused, 'PixelBeanz: Sales are off');
		require(count <= MAX_NFT_PER_TRAN,'PixelBeanz: Exceeds NFT per transaction limit');
		require(_totalMinted() + count <= maxSupply,'PixelBeanz: Aqui no mas hombre');

        uint payForCount = count;
        if(_walletMintedCount[msg.sender] == 0) {
            payForCount--;
        }

		require(
			msg.value >= payForCount * MINT_PRICE,
			'PixelBeanz: Ether value sent is not sufficient'
		);

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}
