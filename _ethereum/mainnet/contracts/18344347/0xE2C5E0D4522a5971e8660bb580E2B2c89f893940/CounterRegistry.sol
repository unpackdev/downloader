// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ERC721A.sol";

/**

   ______                  __               ____             _      __            
  / ____/___  __  ______  / /____  _____   / __ \___  ____ _(_)____/ /________  __
 / /   / __ \/ / / / __ \/ __/ _ \/ ___/  / /_/ / _ \/ __ `/ / ___/ __/ ___/ / / /
/ /___/ /_/ / /_/ / / / / /_/  __/ /     / _, _/  __/ /_/ / (__  ) /_/ /  / /_/ / 
\____/\____/\__,_/_/ /_/\__/\___/_/     /_/ |_|\___/\__, /_/____/\__/_/   \__, /  
                                                   /____/                /____/   

 */

/// @title CounterRegistry
/// @notice Fully onchain NFT gated Counter Registry
/// @author Harrison (@PopPunkOnChain)
/// @author OptimizationFans
contract CounterRegistry is Ownable, ERC721A {

    struct Counter {
        uint256 value;
        address owner;
    }

    mapping (uint256 => Counter) public counterRegistry;

    error UnauthorizedAccess();

    constructor() ERC721A("CounterRegistry", "CREG") {
        _initializeOwner(msg.sender);
    }

    function initializeCounter(uint256 _startingValue) external returns (uint256) {
        uint256 id = _nextTokenId();
        counterRegistry[id] = Counter(_startingValue, msg.sender);
        _mint(msg.sender, 1);

        return id;
    }

    function increment(uint256 _counterId) external {
        Counter storage counter = counterRegistry[_counterId];
        if (counter.owner != msg.sender) revert UnauthorizedAccess();

        unchecked {
            counter.value++;
        }
    }

    function decrement(uint256 _counterId) external {
        Counter storage counter = counterRegistry[_counterId];
        if (counter.owner != msg.sender) revert UnauthorizedAccess();

        unchecked {
            counter.value--;
        }
    }

    function adminIncrementClawback(uint256 _counterId) external onlyOwner {
        unchecked {
            counterRegistry[_counterId].value--;
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override {
        if (from != address(0)) {
            counterRegistry[tokenId].owner = to;
        }
        super.transferFrom(from, to, tokenId);
    }

    function getCounter(uint256 _id) external view returns (uint256, address) {
        Counter memory counter = counterRegistry[_id];
        return (counter.value, counter.owner);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return "https://imgur.com/gX03aPZ";
    }

}