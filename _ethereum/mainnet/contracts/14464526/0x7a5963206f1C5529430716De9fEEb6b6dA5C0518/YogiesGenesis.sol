// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
      _____                   _______                   _____                    _____                    _____                    _____          
     |\    \                 /::\    \                 /\    \                  /\    \                  /\    \                  /\    \         
     |:\____\               /::::\    \               /::\    \                /::\    \                /::\    \                /::\    \        
     |::|   |              /::::::\    \             /::::\    \               \:::\    \              /::::\    \              /::::\    \       
     |::|   |             /::::::::\    \           /::::::\    \               \:::\    \            /::::::\    \            /::::::\    \      
     |::|   |            /:::/~~\:::\    \         /:::/\:::\    \               \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
     |::|   |           /:::/    \:::\    \       /:::/  \:::\    \               \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
     |::|   |          /:::/    / \:::\    \     /:::/    \:::\    \              /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
     |::|___|______   /:::/____/   \:::\____\   /:::/    / \:::\    \    ____    /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /::::::::\    \ |:::|    |     |:::|    | /:::/    /   \:::\ ___\  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /::::::::::\____\|:::|____|     |:::|    |/:::/____/  ___\:::|    |/::\   \/:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/~~~~/~~       \:::\    \   /:::/    / \:::\    \ /\  /:::|____|\:::\  /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    /           \:::\    \ /:::/    /   \:::\    /::\ \::/    /  \:::\/:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /             \:::\    /:::/    /     \:::\   \:::\ \/____/    \::::::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /               \:::\__/:::/    /       \:::\   \:::\____\       \::::/____/              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                 \::::::::/    /         \:::\  /:::/    /        \:::\    \               \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                   \::::::/    /           \:::\/:::/    /          \:::\    \               \:::\   \/____/          \:::\/:::/    /     
                            \::::/    /             \::::::/    /            \:::\    \               \:::\    \               \::::::/    /      
                             \::/____/               \::::/    /              \:::\____\               \:::\____\               \::::/    /       
                              ~~                      \::/____/                \::/    /                \::/    /                \::/    /        
                                                                                \/____/                  \/____/                  \/____/                                                                                                                                                                 
 */


import "./ERC721Y.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract YogiesGenesis is ERC721Y, Ownable {
    using Strings for uint256;

    // ERC721
    address public openseaProxyRegistryAddress;
    string public baseURIString = "https://yogies.mypinata.cloud/ipfs/QmUYvuKkCGDibZs2Fa1Da1ofe3LqnFHNUAVAYvuF2NUhqK/";
    bool public isFrozen = false;

    // staking
    address public yogies;

    modifier notFrozen() {
        require(!isFrozen, "CONTRACT FROZEN");
        _;
    }

    // Events
    event setBaseURIEvent(string indexed baseURI);
    event ReceivedEther(address indexed sender, uint256 indexed amount);

    constructor(
        address _openseaProxyRegistryAddress
    ) ERC721Y("Yogies Genesis", "YG") Ownable() {
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
    }

    function stakeYogie(uint256 yogieId, address sender) external {
        require(yogies != address(0), "Yogies not initialized");
        require(msg.sender == yogies, "Not from yogies");
        
        require(_exists(yogieId), "Yogie does not exist");
        require(_ownershipOf(yogieId).stakeLastClaimTime == 0, "Yogie already staked");
        require(_ownershipOf(yogieId).addr == sender, "Sender does not own yogie");

        _setStakeTime(yogieId);
        emit Transfer(sender, yogies, yogieId);
    }

    function unstakeYogie(uint256 yogieId, address sender) external {
        require(yogies != address(0), "Yogies not initialized");
        require(msg.sender == yogies, "Not from yogies");

        require(_exists(yogieId), "Yogie does not exist");
        require(_ownershipOf(yogieId).stakeLastClaimTime != 0, "Yogie not staked");
        require(_ownershipOf(yogieId).addr == yogies, "Yogie not staked in contract");

        require(_ownerships[yogieId].addr == sender, "Sender does not own yogie");

        _deleteStakeTime(yogieId);
        emit Transfer(yogies, sender, yogieId);
    }

    function updateYogieStakeTime(uint256 yogieId, address sender) external {
        require(yogies != address(0), "Yogies not initialized");
        require(msg.sender == yogies, "Not from yogies");

        require(_exists(yogieId), "Yogie does not exist");
        require(_ownershipOf(yogieId).stakeLastClaimTime != 0, "Yogie not staked");
        require(_ownershipOf(yogieId).addr == yogies, "Yogie not staked in contract");

        require(_ownerships[yogieId].addr == sender, "Sender does not own yogie");

        _setStakeTime(yogieId);
    }

    function mint(address _to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= 10, "Max genesis yogies minted");
        _safeMint(_to, amount, false);
    }

    // Override ownership of to return yogies address when staked instead of address(this)
    function _ownershipOf(uint256 tokenId) internal view override returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    // Yogies contract owns each staked token
                    if (ownership.stakeLastClaimTime != 0) {
                        return TokenOwnership({
                            addr: yogies,
                            stakeLastClaimTime: ownership.stakeLastClaimTime,
                            burned: ownership.burned
                        });
                    }

                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    // view only yogies
    function getStakeLastClaimed(uint256 yogieId) external view returns (uint256) {
        if (_exists(yogieId)) {
            return _ownershipOf(yogieId).stakeLastClaimTime;
        }
        return 0;
    }

    function getStakeOwner(uint256 yogieId) external view returns (address) {
        if (_exists(yogieId)) {
            return _ownerships[yogieId].addr;
        }
        return address(0);
    }

    // view only
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURIString, tokenId.toString(), ".json"));     
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Create an instance of the ProxyRegistry contract from Opensea
        ProxyRegistry proxyRegistry = ProxyRegistry(openseaProxyRegistryAddress);
        // whitelist the ProxyContract of the owner of the Yogies
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        if (openseaProxyRegistryAddress == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _msgSender()
        override
        internal
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    // only owner
    function setBaseURI(string memory _newBaseURI) external onlyOwner notFrozen {
        baseURIString = _newBaseURI;
        emit setBaseURIEvent(_newBaseURI);
    }

    function setYogiesAddress(address newYogies) external onlyOwner notFrozen {
        yogies = newYogies;
    }

    function freeze() external onlyOwner {
        isFrozen = true;
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}