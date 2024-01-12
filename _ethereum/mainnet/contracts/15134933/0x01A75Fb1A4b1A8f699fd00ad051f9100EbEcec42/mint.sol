// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract HumanFly is ERC721A, Ownable, ReentrancyGuard {

    uint public immutable maxSupply = 4444;
    IERC721A public immutable dirtyFlies;
    address public immutable deadAddr = 0x000000000000000000000000000000000000dEaD;

    uint8 public mintPaused = 1;
    uint8 public burnPaused = 1;

    string public baseURI = 'https://static-resource.dirtyflies.xyz/human_fly/metadata/';
    uint public mintLimit = 2;
    uint public cost = 0;
    mapping(address => bool) public whitelistMap;

    mapping(address => uint[]) public mintTokenIdsMap;

    constructor() ERC721A('Human Fly', 'HM') {
        dirtyFlies = IERC721A(0x9984bD85adFEF02Cea2C28819aF81A6D17a3Cb96);
    }

    function enableMint(uint cost_) public onlyOwner {
        mintPaused = 0;
        burnPaused = 1;
        cost = cost_;
    }

    function enableBurn() public onlyOwner {
        mintPaused = 1;
        burnPaused = 0;
    }

    function updatePaused(uint8 mintPaused_, uint8 burnPaused_) public onlyOwner {
        mintPaused = mintPaused_;
        burnPaused = burnPaused_;
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateMintLimit(uint mintLimit_) public onlyOwner {
        mintLimit = mintLimit_;
    }

    function updateCost(uint cost_) public onlyOwner {
        cost = cost_;
    }

    function updateWhitelistMap(address[] memory addAddrs, address[] memory delAddrs) public onlyOwner {
        for (uint i = 0; i < addAddrs.length; i++) {
            whitelistMap[addAddrs[i]] = true;
        }

        for (uint i = 0; i < delAddrs.length; i++) {
            whitelistMap[delAddrs[i]] = false;
        }
    }

    function getCost(address msgSender) public view returns (uint) {
        if (whitelistMap[msgSender]) {
            return 0;
        }
        return cost;
    }

    function calculateCost(address msgSender, uint quantity) public view returns (uint) {
        return quantity * getCost(msgSender);
    }

    function checkPaused() public view {
        require(mintPaused != 1, 'Current action is paused');
    }

    function getMintTokenIds(address msgSender) public view returns (uint[] memory _tokenIds) {
        _tokenIds = mintTokenIdsMap[msgSender];
    }

    function getHoldingTokenIds(address msgSender) public view returns (uint[] memory _tokenIds) {
        uint j = 0;
        _tokenIds = new uint[](dirtyFlies.balanceOf(msgSender));
        for (uint i = 0; i < dirtyFlies.totalSupply(); i++) {
            if (dirtyFlies.ownerOf(i) == msgSender) {
                _tokenIds[j++] = i;
            }
        }
    }

    function burnDirtyFlies(uint[] memory tokenIds) external {
        address msgSender = _msgSender();
        require(burnPaused != 1, 'Current action is paused');
        require(tokenIds.length > 0 && tokenIds.length < 5, 'Invalid tokenIds');

        for (uint i = 0; i < tokenIds.length;) {
            dirtyFlies.transferFrom(msgSender, deadAddr, tokenIds[i]);
        unchecked {
            i++;
        }
        }
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msgSender))) % 100;

        bool success = tokenIds.length == 4 ? true : random < (tokenIds.length * 25);
        if (success) {
            _doMint(msgSender, 1);
        }
    }

    function mint(uint quantity) external payable {
        address msgSender = _msgSender();
        uint expectedCost = calculateCost(msgSender, quantity);

        checkPaused();
        require(quantity > 0, 'Invalid quantity');
        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= expectedCost, 'Insufficient funds');
        require(mintTokenIdsMap[msgSender].length + quantity <= mintLimit, 'Max mints per wallet met');

        _doMint(msgSender, quantity);
        for (uint i = 0; i < quantity; i++) {
            mintTokenIdsMap[msgSender].push(totalSupply() - quantity + i);
        }
    }

    function airdrop(address[] memory mintAddresses, uint[] memory mintCounts) public onlyOwner {
        for (uint i = 0; i < mintAddresses.length; i++) {
            _doMint(mintAddresses[i], mintCounts[i]);
        }
    }

    function airdropForDirtyFliesSpecialHolders() public onlyOwner {
        for (uint i = 0; i < 385; i++) {
            address owner = dirtyFlies.ownerOf(i);
            if (owner != address(0) && owner != deadAddr) {
                _doMint(owner, 1);
            }
        }
    }

    function _doMint(address to, uint quantity) private {
        require(totalSupply() + quantity <= maxSupply, 'Max supply exceeded');
        require(to != address(0) && to != deadAddr, 'Cannot have a non-address as reserve.');
        _safeMint(to, quantity);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os,) = payable(owner()).call{value : address(this).balance}('');
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
