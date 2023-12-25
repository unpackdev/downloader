// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//                            _.-^-._    .--.
//                         .-'   _   '-. |__|
//                        /     |_|     \|  |
//                       /               \  |
//                      /|     _____     |\ |
//                       |    |==|==|    |  |
//   |---|---|---|---|---|    |--|--|    |  |
//   |---|---|---|---|---|    |==|==|    |  |
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//  ______  Harvest.art v3 (BidTicket) _______

import "./ERC1155P.sol";
import "./Ownable.sol";
import "./IBidTicket.sol";

contract BidTicket is ERC1155P, Ownable, IBidTicket {
    address public harvestContract;
    address public auctionsContract;
    mapping(uint256 => string) private _tokenURIs;

    error NotAuthorized();

    modifier onlyMinters() {
        if (msg.sender != harvestContract) {
            if (msg.sender != owner()) {
                revert NotAuthorized();
            }
        }
        _;
    }

    modifier onlyBurners() {
        if (msg.sender != auctionsContract) {
            if (msg.sender != owner()) {
                revert NotAuthorized();
            }
        }
        _;
    }

    constructor() {
        _initializeOwner(msg.sender);
    }

    function name() public view virtual override returns (string memory) {
        return "BidTicket";
    }

    function symbol() public view virtual override returns (string memory) {
        return "TCKT";
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return _tokenURIs[id];
    }

    function mint(address to, uint256 id, uint256 amount) external virtual onlyMinters {
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts) public onlyMinters {
        _mintBatch(to, ids, amounts, "");
    }

    function burn(address from, uint256 id, uint256 amount) external onlyBurners {
        _burn(from, id, amount);
    }

    function burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts) external onlyBurners {
        _burnBatch(from, ids, amounts);
    }

    function setURI(uint256 tokenId, string calldata tokenURI) external virtual onlyOwner {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    function setHarvestContract(address harvestContract_) external onlyOwner {
        harvestContract = harvestContract_;
    }

    function setAuctionsContract(address auctionsContract_) external onlyOwner {
        auctionsContract = auctionsContract_;
    }
}
