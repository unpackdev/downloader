// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ReentrancyGuard.sol";
import "./ERC721Royalty.sol";
import "./ERC721.sol";
import "./MintGate.sol";
import "./Withdrawable.sol";
import "./IGenesisPass.sol";

error ContractMinterAlreadyDefined();
error NotEnoughVotes();
error WinningCollectionsFinalized();

contract GenesisPass is ERC721, ERC721Royalty, IGenesisPass, ReentrancyGuard, Withdrawable {

    uint256 public constant MAX_MINT_PER_WALLET = 2;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MAX_WINNERS = 5;

    uint256 public constant MINT_END_TIME = 0;
    uint256 public constant MINT_START_TIME = 0;

    uint256 public constant PRICE = 0.2 ether;

    uint256 public constant WINNING_VOTES_THRESHOLD = 2500;


    address[] public _collections;

    address public _contractMinter;

    mapping(address => uint256) private _leaderboard;

    mapping(address => uint256) private _votes;

    address[] public _winners;


    constructor() ERC721("Genesis Pass", "genesis") ERC721Royalty(_msgSender(), 1000) ReentrancyGuard() {}


    function collections(uint256 cursor, uint256 size) external view returns(address[] memory, uint256) {
        uint256 n = size;

        if (n > _collections.length - cursor) {
            n = _collections.length - cursor;
        }

        address[] memory values = new address[](n);

        unchecked {
            for (uint256 i = 0; i < n; i++) {
                values[i] = _collections[cursor + i];
            }

            return (values, (cursor + n));
        }
    }

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

    function setContractMinter(address minter) external onlyOwner {
        if (_contractMinter != address(0)) {
            revert ContractMinterAlreadyDefined();
        }

        _contractMinter = minter;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
        return interfaceId == type(IGenesisPass).interfaceId || super.supportsInterface(interfaceId);
    }

    function vote(address collection, uint256 quantity) external whenNotPaused {
        address sender = _msgSender();

        if ((_winners.length + 1) > MAX_WINNERS) {
            revert WinningCollectionsFinalized();
        }

        unchecked {
            if (_contractMinter != sender && _votes[sender] < quantity) {
                revert NotEnoughVotes();
            }

            if (_leaderboard[collection] == 0) {
                _collections.push(collection);
            }

            _leaderboard[collection] += quantity;
            _votes[sender] -= quantity;

            if ((_leaderboard[collection] + 1) > WINNING_VOTES_THRESHOLD) {
                _winners.push(collection);
            }
        }
    }

    function votes(address collection) external view returns(uint256) {
        return _leaderboard[collection];
    }

    function withdraw() external onlyOwner nonReentrant whenNotPaused {
        _withdraw(owner(), address(this).balance);
    }
}
