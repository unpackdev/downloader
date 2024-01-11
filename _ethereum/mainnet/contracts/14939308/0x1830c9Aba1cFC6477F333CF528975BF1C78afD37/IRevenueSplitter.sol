//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface IRevenueSplitter {
    // Collection Management Events
    event CreateCollectionEvent(address indexed collection);
    event AddPayeeEvent(
        address indexed collection,
        address indexed account,
        uint256 shares
    );
    event RemovePayeeEvent(address indexed collection, address indexed account);

    // Token $$ Events
    event BuyEvent(address indexed collection, uint256 tokenId, uint256 amount);
    event RoyaltyEvent(address indexed collection, uint256 amount);

    // Collaborator $$ Events
    event WithdrawEvent(address indexed payee, uint256 amount);
    event DepositEvent(
        address indexed collection,
        address indexed payee,
        uint256 amount
    );

    // Payout Events
    event SweepEvent(
        address indexed payee,
        address indexed recipient,
        uint256 amount
    );
    event PayoutEvent(address indexed payee, uint256 amount);

    function createCollection(
        string memory name,
        string memory symbol,
        uint256 royaltyAmount,
        address[] memory _payees,
        uint256[] memory _shares,
        string memory baseURI,
        address minter
    ) external returns (address);

    function addCollectionPayees(
        address _collection,
        address[] memory _payee,
        uint256[] memory shares
    ) external;

    function addCollectionPayee(
        address _collection,
        address _payee,
        uint256 shares
    ) external;

    function removeCollectionPayee(address _collection, address _payee)
        external;

    function buyNFT(
        address payable _collection,
        uint256 tokenId,
        uint256 expiryBlock,
        bytes calldata signature
    ) external payable;

    function sweep(address _payee, address payable _recipient) external;

    function payout(address payable _payee) external;

    function withdraw() external;

    function depositRoyalty(address _collection) external payable;
}
