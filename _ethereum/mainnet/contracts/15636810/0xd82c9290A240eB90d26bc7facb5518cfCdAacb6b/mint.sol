// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract TheFdaFoodCollection is ERC721A, Ownable, ReentrancyGuard {

    uint public immutable maxSupply = 8000;

    string public baseURI = 'https://arweave.net/Gfi0S1BovxcqRFitnHV89OFxAHe_fMrmeC2ZDeKK01Y/';
    bytes32 public merkleRoot;

    uint public publicSaleFreeMintCount = 1;
    uint public publicSaleMintCost = 0.003 ether;
    uint public publicSaleMintLimit = 4;
    uint public publicSaleOpenTimestamp = 1664467200;

    uint public whiteListSaleMintLimit = 2;
    uint public whiteListSaleOpenTimestamp = 1664465400;

    mapping(address => uint) public publicSaleMintCountMap;
    mapping(address => uint) public whiteListSaleMintCountMap;

    constructor() ERC721A('TheFdaFoodCollection', 'TheFdaFoodCollection') {
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function configPublicSale(uint publicSaleFreeMintCount_, uint publicSaleMintCost_, uint publicSaleMintLimit_, uint publicSaleOpenTimestamp_) public onlyOwner {
        require(publicSaleOpenTimestamp_ >= whiteListSaleOpenTimestamp, 'Invalid publicSaleOpenTimestamp_ input!');
        publicSaleFreeMintCount = publicSaleFreeMintCount_;
        publicSaleMintCost = publicSaleMintCost_;
        publicSaleMintLimit = publicSaleMintLimit_;
        publicSaleOpenTimestamp = publicSaleOpenTimestamp_;
    }

    function configWhiteListSale(uint whiteListSaleMintLimit_, uint whiteListSaleOpenTimestamp_) public onlyOwner {
        require(publicSaleOpenTimestamp >= whiteListSaleOpenTimestamp_, 'Invalid whiteListSaleOpenTimestamp_ input!');
        whiteListSaleMintLimit = whiteListSaleMintLimit_;
        whiteListSaleOpenTimestamp = whiteListSaleOpenTimestamp_;
    }

    function currentMintLimit() public view returns (uint) {
        uint blockTimestamp = block.timestamp;
        if (blockTimestamp >= publicSaleOpenTimestamp) {
            return publicSaleMintLimit;
        } else {
            return whiteListSaleMintLimit;
        }
    }

    function calculateRemainMintLimit(address addr, bytes32[] calldata merkleProof) public view returns (uint) {
        uint blockTimestamp = block.timestamp;
        if (blockTimestamp >= publicSaleOpenTimestamp) {
            return publicSaleMintLimit - publicSaleMintCountMap[addr];
        } else {
            return whiteListSaleMintLimit - whiteListSaleMintCountMap[addr];
        }
    }

    function isInWhiteList(address addr, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function calculateCost(address addr, uint mintCount) public view returns (uint) {
        uint blockTimestamp = block.timestamp;
        if (blockTimestamp >= publicSaleOpenTimestamp) {
            if (publicSaleFreeMintCount > publicSaleMintCountMap[addr]) {
                uint remainFreeMintCount = publicSaleFreeMintCount - publicSaleMintCountMap[addr];
                if (remainFreeMintCount >= mintCount) {
                    return 0;
                } else {
                    return (mintCount - remainFreeMintCount) * publicSaleMintCost;
                }
            } else {
                return mintCount * publicSaleMintCost;
            }
        } else {
            return 0;
        }
    }

    function checkCanMint(address addr, bytes32[] calldata merkleProof, uint mintCount) public view {
        uint blockTimestamp = block.timestamp;
        require(addr != address(0), 'Cannot have a non-address as reserve');
        require(blockTimestamp >= whiteListSaleOpenTimestamp, 'Public-Sale/WhiteList-Sale is not open yet!');
        require(maxSupply >= totalSupply() + mintCount, 'Max supply met');

        if (blockTimestamp >= publicSaleOpenTimestamp) {
            require(publicSaleMintCountMap[addr] + mintCount <= publicSaleMintLimit, 'Max mints per wallet met');
        } else {
            require(isInWhiteList(addr, merkleProof), 'Address is not in white list');
            require(whiteListSaleMintCountMap[addr] + mintCount <= whiteListSaleMintLimit, 'Max mints per wallet met');
        }
        require(address(addr).balance > calculateCost(addr, mintCount), 'Address balance not enough');
    }

    function mint(bytes32[] calldata merkleProof, uint mintCount) external payable {
        address msgSender = _msgSender();
        uint expectedCost = calculateCost(msgSender, mintCount);

        checkCanMint(msgSender, merkleProof, mintCount);
        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= expectedCost, 'Insufficient funds');

        bool isPublicSale = block.timestamp >= publicSaleOpenTimestamp;
        _doMint(msgSender, mintCount);

        if (isPublicSale) {
            publicSaleMintCountMap[msgSender] += mintCount;
        } else {
            whiteListSaleMintCountMap[msgSender] += mintCount;
        }
    }

    function airdrop(address[] memory toAddresses, uint[] memory mintCounts) public onlyOwner {
        for (uint i = 0; i < toAddresses.length; i++) {
            _doMint(toAddresses[i], mintCounts[i]);
        }
    }

    function _doMint(address to, uint mintCount) private {
        require(totalSupply() + mintCount <= maxSupply, 'Max supply exceeded');
        require(to != address(0), 'Cannot have a non-address as reserve');
        _safeMint(to, mintCount);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os,) = payable(owner()).call{value : address(this).balance}('');
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
