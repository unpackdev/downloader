//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract CuneiformToken is ERC721, Ownable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 public constant TICKETCLERK_ROLE = keccak256("TICKETCLERK_ROLE");

    mapping (uint256 => uint256) public ticketAssetId;
    mapping (uint256 => uint256) public ticketTypeId;

    string _currentBaseURI = "https://metadata.cuneiform.ai/";
    event TicketMinted(uint256 ticketId, uint256 assetId, uint256 typeId);

    constructor(address initialRecipient, uint256 assetId, uint256 ticketCount, uint256 marketplaceCount)
    ERC721("CuneiformNFT", "CNF")
    {
      _setupRole(getRoleAdmin(TICKETCLERK_ROLE), msg.sender);
      grantRole(TICKETCLERK_ROLE, msg.sender);

      // generate ticketCount tickets to the initialRecipient
      for (uint i=1; i<=ticketCount; i++) {
        mintNFT(initialRecipient, assetId, 1);
      }

      // generate marketplaceCount marketplace items to the initialRecipient
      for (uint j=1; j<=marketplaceCount; j++) {
        mintNFT(initialRecipient, assetId, 2);
      }

    }

    function supportsInterface(bytes4 interfaceId)
      public view virtual override(ERC721, AccessControl)
      returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal view override
        returns (string memory)
    {
        return _currentBaseURI;
    }

    function setBaseURI(string memory newBaseURI)
        public onlyOwner
      {
        _currentBaseURI = newBaseURI;
      }

    function issueTicket(address recipient, uint256 assetId, uint256 typeId)
        public
        returns (uint256)
    {
        require(hasRole(TICKETCLERK_ROLE, msg.sender), "Caller is not a ticket clerk");
        uint256 newItemId = mintNFT(recipient, assetId, typeId);
        return newItemId;
    }

    function batchMintTickets(address recipient, uint256 assetId, uint256 typeId, uint256 ticketCount)
        public
    {
        require(hasRole(TICKETCLERK_ROLE, msg.sender), "Caller is not a ticket clerk");
        for (uint i=1; i<=ticketCount; i++) {
          mintNFT(recipient, assetId, typeId);
        }
    }

    function mintNFT(address recipient, uint256 assetId, uint256 typeId)
        private
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);


        ticketAssetId[newItemId] = assetId;
        ticketTypeId[newItemId] = typeId;
        emit TicketMinted(newItemId, assetId, typeId);

        return newItemId;
    }


    function ticketsOfOwner(address _owner)
        view public
        returns(uint256[] memory)
    {
        uint256 ticketCount = balanceOf(_owner);

        if (ticketCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](ticketCount);
            uint256 totalTickets = _tokenIds.current();
            uint256 resultIndex = 0;

            // We count on the fact that all tokens have IDs starting at 1 and increasing
            // sequentially up to the totalTickets count.
            uint256 ticketId;

            for (ticketId = 1; ticketId <= totalTickets; ticketId++) {
                if (ownerOf(ticketId) == _owner) {
                    result[resultIndex] = ticketId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function getTicketTypeId(uint256 ticketId)
        view public
        returns (uint256)
    {
        return ticketTypeId[ticketId];
    }

}
