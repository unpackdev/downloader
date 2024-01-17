// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC1155.sol";

contract Maya is ERC1155, Ownable {
    uint256 public numTokens = 0;
    string public name = "Maya";
    string public symbol = "MAYA";
    address public crossmintAddress =
        0xdAb1a1854214684acE522439684a145E62505233;

    event Crossmint(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount
    );
    event Mint(address indexed to, uint256 indexed tokenId, uint256 amount);
    event Lend(
        address indexed lender,
        uint256 indexed tokenId,
        uint256 duration,
        uint256 timestamp,
        bytes32 listingId
    );
    event Rent(
        address indexed renter,
        address indexed lender,
        uint256 indexed tokenId,
        uint256 duration,
        uint256 timestamp,
        bytes32 listingId
    );
    event Removed(
        address indexed lender,
        address indexed renter,
        uint256 indexed tokenId,
        bytes32 listingId
    );

    struct Token {
        uint256 publicPrice;
        uint256 allowlistPrice;
        uint256 totalSupply;
        uint256 minted;
        uint256 startTime;
        uint256 endTime;
        string uri;
        bytes32 merkleRoot;
    }

    struct Lending {
        address payable lender;
        uint256 duration;
        uint256 tokenId;
        uint256 price;
        uint256 timestamp;
    }

    struct Renting {
        address renter;
    }

    struct LendingRenting {
        Lending lending;
        Renting renting;
    }

    mapping(uint256 => Token) public tokens;
    mapping(bytes32 => LendingRenting) public listings;
    mapping(address => mapping(uint256 => uint256)) public lendingBalances;

    constructor() ERC1155("") {}

    function _leaf(string memory tokenId, string memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, tokenId));
    }

    function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
        crossmintAddress = _crossmintAddress;
    }

    function lend(
        uint256 tokenId,
        uint256 duration,
        uint256 price
    ) public {
        bytes32 listingId = keccak256(
            abi.encodePacked(msg.sender, tokenId, duration, block.timestamp)
        );
        require(
            block.timestamp >=
                block.timestamp + listings[listingId].lending.duration,
            "Maya: Lending period has not ended"
        );
        require(
            listings[listingId].lending.tokenId == tokenId,
            "Maya: Token ID does not match"
        );
        require(
            listings[listingId].lending.lender == address(0),
            "Maya: Lending period has not started"
        );
        require(
            lendingBalances[msg.sender][tokenId] <
                balanceOf(msg.sender, tokenId),
            "Maya: Cant lend more than you own"
        );

        listings[listingId].lending.lender = payable(msg.sender);
        listings[listingId].lending.duration = duration;
        listings[listingId].lending.price = price;
        listings[listingId].lending.timestamp = block.timestamp;

        lendingBalances[msg.sender][tokenId] += 1;

        emit Lend(msg.sender, tokenId, duration, block.timestamp, listingId);
    }

    function rent(bytes32 listingId) public payable {
        require(
            listings[listingId].lending.lender != address(0),
            "Maya: Invalid listing ID"
        );
        require(
            listings[listingId].lending.price == msg.value,
            "Maya: Price does not match"
        );
        require(
            listings[listingId].renting.renter == address(0),
            "Maya: Token is already rented"
        );

        listings[listingId].renting.renter = payable(msg.sender);
        listings[listingId].lending.lender.transfer(msg.value);

        emit Rent(
            msg.sender,
            listings[listingId].lending.lender,
            listings[listingId].lending.tokenId,
            listings[listingId].lending.duration,
            listings[listingId].lending.timestamp,
            listingId
        );
    }

    function removeListing(bytes32 listingId) public {
        require(
            listings[listingId].lending.lender == msg.sender,
            "Maya: Only lender can remove listing"
        );
        require(
            listings[listingId].renting.renter == address(0) ||
                block.timestamp >=
                listings[listingId].lending.timestamp +
                    listings[listingId].lending.duration,
            "Maya: Renting period has not ended"
        );

        if (
            lendingBalances[msg.sender][listings[listingId].lending.tokenId] > 0
        ) {
            lendingBalances[msg.sender][
                listings[listingId].lending.tokenId
            ] -= 1;
        }

        delete listings[listingId];

        emit Removed(
            msg.sender,
            listings[listingId].renting.renter,
            listings[listingId].lending.tokenId,
            listingId
        );
    }

    function getListingById(bytes32 listingId)
        public
        view
        returns (LendingRenting memory)
    {
        return listings[listingId];
    }

    function getListing(
        address lender,
        uint256 tokenId,
        uint256 duration,
        uint256 timestamp
    ) public view returns (LendingRenting memory) {
        bytes32 listingId = keccak256(
            abi.encodePacked(lender, tokenId, duration, timestamp)
        );
        return listings[listingId];
    }

    function mint(
        uint256 tokenId,
        uint256 count,
        bytes32[] calldata proof
    ) external payable {
        require(tokenId <= numTokens, "invalid token id");

        if (msg.sender != owner()) {
            string memory payload = string(abi.encodePacked(msg.sender));

            uint256 price = tokens[tokenId].allowlistPrice;

            if (proof.length == 0) {
                price = tokens[tokenId].publicPrice;
            } else {
                require(
                    MerkleProof.verify(
                        proof,
                        tokens[tokenId].merkleRoot,
                        _leaf(Strings.toString(tokenId), payload)
                    ),
                    "invalid proof"
                );
            }

            require(
                block.timestamp > tokens[tokenId].startTime &&
                    block.timestamp < tokens[tokenId].endTime,
                "token not active"
            );
            if (tokens[tokenId].totalSupply > 0) {
                require(
                    tokens[tokenId].minted + count <=
                        tokens[tokenId].totalSupply,
                    "exceeds total supply"
                );
            }
            require(count * price == msg.value, "invalid value");
        }

        tokens[tokenId].minted += count;
        _mint(msg.sender, tokenId, count, "");

        emit Mint(msg.sender, tokenId, count);
    }

    function crossmint(
        address to,
        uint256 tokenId,
        uint256 count
    ) public payable {
        require(tokenId <= numTokens, "invalid token id");
        require(
            msg.value >= tokens[tokenId].publicPrice * count,
            "invalid value"
        );
        require(
            tokens[tokenId].minted + count <= tokens[tokenId].totalSupply,
            "exceeds total supply"
        );
        require(
            msg.sender == crossmintAddress,
            "this function is for crossmint only"
        );
        require(
            block.timestamp > tokens[tokenId].startTime &&
                block.timestamp < tokens[tokenId].endTime,
            "token not active"
        );

        tokens[tokenId].minted += count;
        _mint(to, tokenId, count, "");

        emit Crossmint(to, tokenId, count);
    }

    function addToken(
        uint256 _publicPrice,
        uint256 _allowlistPrice,
        uint256 _totalSupply,
        uint256 _startTime,
        uint256 _endTime,
        string memory _uri,
        bytes32 _merkleRoot
    ) public onlyOwner {
        Token storage token = tokens[numTokens];
        token.publicPrice = _publicPrice;
        token.allowlistPrice = _allowlistPrice;
        token.totalSupply = _totalSupply;
        token.startTime = _startTime;
        token.endTime = _endTime;
        token.uri = _uri;
        token.merkleRoot = _merkleRoot;

        numTokens += 1;
    }

    function editToken(
        uint256 tokenId,
        uint256 _publicPrice,
        uint256 _allowlistPrice,
        uint256 _totalSupply,
        uint256 _startTime,
        uint256 _endTime,
        string memory _uri,
        bytes32 _merkleRoot
    ) public onlyOwner {
        Token storage token = tokens[tokenId];
        token.publicPrice = _publicPrice;
        token.allowlistPrice = _allowlistPrice;
        token.totalSupply = _totalSupply;
        token.startTime = _startTime;
        token.endTime = _endTime;
        token.uri = _uri;
        token.merkleRoot = _merkleRoot;
    }

    function editAllowlist(uint256 tokenId, bytes32 _merkleRoot)
        public
        onlyOwner
    {
        tokens[tokenId].merkleRoot = _merkleRoot;
    }

    function editPublicPrice(uint256 tokenId, uint256 _publicPrice)
        public
        onlyOwner
    {
        tokens[tokenId].publicPrice = _publicPrice;
    }

    function editAllowlistPrice(uint256 tokenId, uint256 _allowlistPrice)
        public
        onlyOwner
    {
        tokens[tokenId].allowlistPrice = _allowlistPrice;
    }

    function editTotalSupply(uint256 tokenId, uint256 _totalSupply)
        public
        onlyOwner
    {
        tokens[tokenId].totalSupply = _totalSupply;
    }

    function editStartTime(uint256 tokenId, uint256 _startTime)
        public
        onlyOwner
    {
        tokens[tokenId].startTime = _startTime;
    }

    function editEndTime(uint256 tokenId, uint256 _endTime) public onlyOwner {
        tokens[tokenId].endTime = _endTime;
    }

    function editUri(uint256 tokenId, string memory _uri) public onlyOwner {
        tokens[tokenId].uri = _uri;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "failed to receive ether");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokens[tokenId].uri;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 tokenId = ids[i];
                uint256 amount = amounts[i];
                uint256 fromBalance = balanceOf(from, tokenId);
                uint256 lendingBalance = lendingBalances[from][tokenId];
                require(
                    fromBalance >= lendingBalance,
                    "cannot transfer lending token"
                );
                require(
                    fromBalance - lendingBalance >= amount,
                    "cannot transfer lending token"
                );
            }
        }
    }
}
