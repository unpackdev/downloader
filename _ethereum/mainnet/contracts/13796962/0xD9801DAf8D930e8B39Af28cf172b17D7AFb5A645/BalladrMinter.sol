/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Balladr.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

struct Ticket {
    // Ticket ID issued by backend
    bytes32 ticketId;
    // Token ID to mint
    uint256 tokenId;
    // Price for each token in wei
    uint256 price;
    // Max supply
    uint256 supply;
    // Uri of the token
    string uri;
    // Original creator of the token
    address payable minter;
    // minting only available after this date (timestamp in second)
    uint256 availableAfter;
    // minting only available after this date (timestamp in second)
    uint256 availableBefore;
    // Signature issued by backend
    bytes signature;
    // fees amount in wei for each token
    uint256 fees;
    // if true, then the tokenUri cannot be modified
    bool isFrozen;
    // id of the collection
    uint256 collectionId;
    // Number signed by original creator
    uint256 requestId;
    // Signature of original creator
    bytes requestSignature;
}

contract BalladrMinter is EIP712 {
    // Owner of the contract
    address payable public owner;

    // This contract will manage the ERC1155 contract
    Balladr private ERC_target;

    // Address of the backend ticket signer
    address private signer;

    // Signature domain
    string private constant SIGNING_DOMAIN = "Balladr";

    // Signature version
    string private constant SIGNATURE_VERSION = "1";

    // List of canceled tickets
    mapping(bytes32 => bool) private ticketCanceled;

    /**
    * @notice Only the contract owner or token creator can use the modified function
    */
    modifier onlyOwnerOrCreator(uint256 _tokenId) {
        require(
            msg.sender == owner ||
                ERC_target.getTokenOriginalCreator(_tokenId) == msg.sender
        , "Not Allowed");
        _;
    }

    /**
    * @notice Only the contract owner or collection owner can use the modified function
    */
    modifier onlyOwnerOrCollectionCreator(uint256 _collectionId) {
        require(
            msg.sender == owner ||
                ERC_target.getCollectionOwner(_collectionId) == msg.sender
        , "Not Allowed");
        _;
    }

    /**
    * @notice Cancel a ticket. Minting with a canceled ticketId will be forbidden
    */
    function cancelTicket(Ticket calldata ticket) public {
        // Check if backend signature is right to prevent anyone from cancelling tickets
        address _signer = _verifyTicket(ticket);
        require(_signer == signer, "BAD TICKET");
        // Check if ticket issuer is the original creator or the contract owner
        require(msg.sender == owner || _verifyRequestId(ticket) == msg.sender);
        // Cancel a ticketId
        ticketCanceled[ticket.ticketId] = true;
    }

    /**
    * @notice Withdraw fund for Contract owner
    */
    function withdraw(uint256 amount) public payable {
        require(msg.sender == owner);
        require(amount <= address(this).balance);
        owner.transfer(amount);
    }

    /**
    * @notice Freeze tokenUri
    * Logic can be found in ERC1155 contract
    */
    function freezeTokenUri(uint256 _tokenId) public onlyOwnerOrCreator(_tokenId) {
        ERC_target.freezeTokenUri(_tokenId);
    }

    /**
    * @notice Set the Uri for a given token
    * Logic can be found in ERC1155 contract
    */
    function setTokenUri(uint256 _tokenId, string memory _uri) public onlyOwnerOrCreator(_tokenId) {
        ERC_target.setTokenUri(_tokenId, _uri);
    }

    /**
    * @notice Close a collection
    * Logic can be found in ERC1155 contract
    */
    function closeCollection(uint256 _collectionId) public onlyOwnerOrCollectionCreator(_collectionId) {
        ERC_target.setCloseCollection(_collectionId);
    }

    /**
    * @notice Update Collection Owner
    * Logic can be found in ERC1155 contract
    */
    function setCollectionOwner(uint256 _collectionId, address newOwner) public onlyOwnerOrCollectionCreator(_collectionId) {
        ERC_target.setCollectionOwner(_collectionId, newOwner);
    }

    /**
    * @notice Set Collection Alternative Payment Address
    * Logic can be found in ERC1155 contract
    */
    function setCollectionPaymentAddress(uint256 _collectionId, address _paymentAddress) public onlyOwnerOrCollectionCreator(_collectionId) {
        ERC_target.setCollectionPaymentAddress(_collectionId, _paymentAddress);
    }

    /**
    * @notice Set Collection Custom Royalties
    * Logic can be found in ERC1155 contract
    */
    function setCollectionCustomRoyalties(uint256 _collectionId, uint256 _royalties) public onlyOwnerOrCollectionCreator(_collectionId) {
        ERC_target.setCollectionRoyalties(_collectionId, _royalties);
    }

    /**
    * @notice Mint with a ticket issued by Balladr's backend
    */
    function mint(
        // Ticket
        Ticket calldata ticket,
        // Amount of tokens to mint
        uint256 amount,
        // Address that will receive the token
        address to
    ) public payable {
        // Verify if backend signature is right
        address _signer = _verifyTicket(ticket);
        require(_signer == signer, "BAD TICKET");

        // Verify if original creator signature is right
        address _sellerSigner = _verifyRequestId(ticket);
        require(_sellerSigner == ticket.minter, "BAD SELLER TICKET");

        // Verify if ticket has been canceled
        require(ticketCanceled[ticket.ticketId] == false, "TICKET CANCELED");

        // Verify if enough eth were sent
        require(msg.value >= (ticket.price * amount), "BAD PRICE");

        // Verify if token availability dates are correct
        require(block.timestamp >= ticket.availableAfter, "NOT FOR SALE YET");
        require(block.timestamp <= ticket.availableBefore, "SALE OVER");

        // Use the mintWrapper to mint token
        ERC_target.mintWrapper(
            ticket.minter,
            to,
            ticket.tokenId,
            amount,
            ticket.uri,
            ticket.supply,
            ticket.isFrozen,
            ticket.collectionId,
            ""
        );

        /// Transfer fund to the creator of the token
        ticket.minter.transfer((ticket.price - ticket.fees) * amount);
    }

    /**
    * @notice Verify the EIP712 signature issued by the creator of the token
    */
    function _verifyRequestId(Ticket calldata ticket)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashrequestId(ticket);
        return ECDSA.recover(digest, ticket.requestSignature);
    }

    /**
    * @notice Hash the EIP712 signature issued by the creator of the token
    */
    function _hashrequestId(Ticket calldata ticket)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("Ticket(uint256 requestId)"),
                        ticket.requestId
                    )
                )
            );
    }

    /**
    * @notice Verify the EIP712 signature issued by Balladr's backend
    */
    function _verifyTicket(Ticket calldata ticket)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTicket(ticket);
        return ECDSA.recover(digest, ticket.signature);
    }

    /**
    * @notice Hash the EIP712 signature issued by Balladr's backend
    */
    function _hashTicket(Ticket calldata ticket)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Ticket(bytes32 ticketId,uint256 tokenId,uint256 price,uint256 supply,string uri,address minter,uint256 availableAfter,uint256 availableBefore,uint256 fees,bool isFrozen,uint256 collectionId)"
                        ),
                        ticket.ticketId,
                        ticket.tokenId,
                        ticket.price,
                        ticket.supply,
                        keccak256(bytes(ticket.uri)),
                        ticket.minter,
                        ticket.availableAfter,
                        ticket.availableBefore,
                        ticket.fees,
                        ticket.isFrozen,
                        ticket.collectionId
                    )
                )
            );
    }

    /**
    * @notice Set a new owner for the Minter contract
    */
    function setOwner(address payable _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    /**
    * @notice Set a new back signer for this contract
    */
    function setSigner(address payable _signer) public {
        require(msg.sender == owner);
        signer = _signer;
    }

    constructor(address _contractTarget, address _signer)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        owner = payable(msg.sender);
        signer = _signer;
        ERC_target = Balladr(_contractTarget);
    }
}
