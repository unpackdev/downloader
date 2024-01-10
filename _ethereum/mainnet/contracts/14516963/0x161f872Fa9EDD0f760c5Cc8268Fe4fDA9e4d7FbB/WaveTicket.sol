// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC721.sol";
import "./WaveProtectedSale.sol";
import "./WaveTicketInfo.sol";

contract WaveTicket is ERC721, Ownable, WaveProtectedSale {
    address private constant OWNER_A = 0xAbB54DfB1FF9B2733D7E34BC473807C0D5e41945;
    address private constant OWNER_B = 0x7Da7A0a5DfF972c5c0B15414Be23E206E33B553c;
    address private constant OWNER_C = 0x90d5B0e08C0092c56d8834540afD0Cf3D0291715;

    uint16 private nextTicketId = 4;
    bool private transferControlEnabled = true;    
    mapping(address => TicketInfo) private addressToTicketInfo;
    mapping(uint16 => bool) private ticketIdToTransferable;

    constructor() ERC721("Wave Ticket", "WAVE") WaveProtectedSale("Wave Ticket", "1") {
        _safeMint(OWNER_A, 1);
        _safeMint(OWNER_B, 2);
        _safeMint(OWNER_C, 3);
        addressToTicketInfo[OWNER_A] = TicketInfo(1, TicketType.LIFETIME, 4102491600, 0, 0);
        addressToTicketInfo[OWNER_B] = TicketInfo(2, TicketType.LIFETIME, 4102491600, 0, 0);
        addressToTicketInfo[OWNER_C] = TicketInfo(3, TicketType.LIFETIME, 4102491600, 0, 0);
    }

    function purchase(
        TicketInfo memory ticketInfo,
        uint128 signedPrice,
        uint32 nonce,
        bytes memory signature
    )
        external
        payable
        isTransactionAuthorized(ticketInfo, signedPrice, nonce, signature)
    {
        require(balanceOf(msg.sender) == 0, "Max 1 ticket per user");
        require(msg.value >= signedPrice, "Insufficient ETH");
        require(block.timestamp < ticketInfo.expiration, "Signature expired");

        uint16 currentTicketId = nextTicketId;
        _safeMint(msg.sender, currentTicketId);

        ticketInfo.id = nextTicketId;
        addressToTicketInfo[msg.sender] = ticketInfo;

        unchecked {
            currentTicketId++;
        }
        nextTicketId = currentTicketId;
    }
    
    function renew() external payable {
        TicketInfo memory ownedTicketInfo = this.getTicketInfo(msg.sender);
        require(msg.value >= ownedTicketInfo.renewalPrice, "Insufficient ETH");

        if (block.timestamp > ownedTicketInfo.expiration) {
            addressToTicketInfo[msg.sender].expiration = uint32(block.timestamp) + ownedTicketInfo.renewalPeriod;
        }
        else {
            addressToTicketInfo[msg.sender].expiration += ownedTicketInfo.renewalPeriod;
        }        
    }

    function upgrade(
        TicketInfo memory ticketInfo,
        uint128 signedPrice,
        uint32 nonce,
        bytes memory signature
    )
        external
        payable
        isTransactionAuthorized(ticketInfo, signedPrice, nonce, signature)
    {
        TicketInfo memory ownedTicketInfo = this.getTicketInfo(msg.sender);
        require(msg.value >= signedPrice, "Insufficient ETH");
        require(ticketInfo.id == ownedTicketInfo.id, "Ticket id mismatch");

        addressToTicketInfo[msg.sender] = ticketInfo;
    }

    function getTicketInfo(address owner) external view returns (TicketInfo memory) {
        require(balanceOf(owner) == 1, "No ticket owned");
        return addressToTicketInfo[owner];
    }

    // Owners

    function withdrawFunds() external onlyOwner {
        uint256 split = address(this).balance / 4;
        uint256 ownerAShare = split * 2;
        uint256 ownerBShare = split;
        uint256 ownerCShare = split;

        (bool resultA, ) = OWNER_A.call{value: ownerAShare}("");
        (bool resultB, ) = OWNER_B.call{value: ownerBShare}("");
        (bool resultC, ) = OWNER_C.call{value: ownerCShare}("");
        require(resultA && resultB && resultC);
    }    

    function ban(address user) external onlyOwner {
        TicketInfo memory ownedTicketInfo = this.getTicketInfo(user);
        _burn(ownedTicketInfo.id);
        delete addressToTicketInfo[user];
    }

    function setTransferStatus(uint16 ticketId, bool status) external onlyOwner {
        ticketIdToTransferable[ticketId] = status;
    }

    function flipTransferControl() external onlyOwner {
        transferControlEnabled = !transferControlEnabled;
    }

    // Overrides

    function _beforeTokenTransfer(address from, address to, uint256 ticketId) internal override (ERC721) {
        if (from == address(0) || to == address(0))
            return;

        if (transferControlEnabled)
            require(ticketIdToTransferable[uint16(ticketId)], "Ticket not transferable");
        require(balanceOf(to) == 0, "Recipient already owns ticket");

        TicketInfo memory ownedTicketInfo = this.getTicketInfo(from);
        require(ownedTicketInfo.id == ticketId, "Ticket id mismatch");
        
        addressToTicketInfo[to] = ownedTicketInfo;
        delete addressToTicketInfo[from];
        delete ticketIdToTransferable[uint16(ticketId)];
        super._beforeTokenTransfer(from, to, ticketId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://meta.wavexaio.com/";
    }
}