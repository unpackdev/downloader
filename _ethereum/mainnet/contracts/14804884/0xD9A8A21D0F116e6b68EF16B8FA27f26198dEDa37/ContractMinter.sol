// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ReentrancyGuard.sol";
import "./ERC721Royalty.sol";
import "./ERC721.sol";
import "./MintGate.sol";
import "./Withdrawable.sol";
import "./IGenesisPass.sol";

error NotEnoughVotes();

contract ContractMinter is ERC721, ERC721Royalty, ReentrancyGuard, Withdrawable {

    uint256 public constant MAX_MINT_PER_WALLET = 2;
    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public constant MINT_END_TIME = 0;
    uint256 public constant MINT_START_TIME = 0;

    uint256 public constant PRICE = 0.1 ether;


    IGenesisPass public _genesisPass;

    mapping(address => uint256) private _votes;


    constructor() ERC721("Contract Minter", "minter") ERC721Royalty(_msgSender(), 1000) ReentrancyGuard() {}


    function mint(uint256 quantity) external nonReentrant payable {
        uint256 available = MAX_SUPPLY - totalMinted();
        address buyer = _msgSender();

        MintGate.price(buyer, PRICE, quantity, msg.value);
        MintGate.supply(available, MAX_MINT_PER_WALLET, uint256(_owner(buyer).minted), quantity);
        MintGate.time(MINT_END_TIME, MINT_START_TIME);

        _safeMint(buyer, quantity);

        unchecked {
            _votes[buyer] += quantity;
        }
    }

    function setGenesisPass(IGenesisPass pass) external onlyOwner {
        _genesisPass = pass;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function vote(address collection, uint256 quantity) external whenNotPaused {
        address sender = _msgSender();

        unchecked {
            if (_votes[sender] < quantity) {
                revert NotEnoughVotes();
            }

            _votes[sender] -= quantity;

            IGenesisPass(_genesisPass).vote(collection, quantity);
        }
    }

    function withdraw() external onlyOwner nonReentrant whenNotPaused {
        _withdraw(owner(), address(this).balance);
    }
}
