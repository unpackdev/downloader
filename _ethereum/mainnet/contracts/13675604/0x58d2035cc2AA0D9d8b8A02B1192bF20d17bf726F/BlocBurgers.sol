// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

/*
                                    ████████████████████
                                  ██                    ██
                                ██    ██          ██      ██
                              ██      ████        ████      ██
                              ██            ████            ██
                              ██                            ██
                            ████████████████████████████████████
                            ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
                              ████████████████████████████████
                            ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
                              ██░░██░░░░██████░░░░░░██░░░░████
                              ████  ████      ██████  ████  ██
                              ██                            ██
                                ████████████████████████████


████████╗██╗████████╗ ██████╗     ██╗    ██╗ █████╗ ███████╗    ██╗  ██╗███████╗██████╗ ███████╗
╚══██╔══╝██║╚══██╔══╝██╔═══██╗    ██║    ██║██╔══██╗██╔════╝    ██║  ██║██╔════╝██╔══██╗██╔════╝
   ██║   ██║   ██║   ██║   ██║    ██║ █╗ ██║███████║███████╗    ███████║█████╗  ██████╔╝█████╗
   ██║   ██║   ██║   ██║   ██║    ██║███╗██║██╔══██║╚════██║    ██╔══██║██╔══╝  ██╔══██╗██╔══╝
   ██║   ██║   ██║   ╚██████╔╝    ╚███╔███╔╝██║  ██║███████║    ██║  ██║███████╗██║  ██║███████╗
   ╚═╝   ╚═╝   ╚═╝    ╚═════╝      ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝

*/

contract BlocBurgers is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public ticketCounter = 0;

    uint256 public reservationPrice = 0.069 ether;

    uint256 public maxReservePerTransaction = 20;
    uint256 public maxReservePublic = 40;
    uint256 public maxReservePresale = 2;
    uint256 public maxTotalSupply = 4200;

    bool public presaleAllowed = false;
    bool public publicSaleAllowed = false;
    bool public publicClaimAllowed = false;
    bool public provenanceHashLocked = false;

    mapping(address => uint256) public reservedPresaleClaims;
    mapping(address => uint256) public reservedPublicClaims;

    mapping(address => uint256) public presaleClaimCounts;
    mapping(address => uint256) public publicClaimCounts;

    string public baseURI;
    string public provenanceHash = "";

    address private withdrawAddress = address(0);
    bytes32 private merkleRoot;

    constructor(string memory name, string memory symbol, address _withdrawAddress) ERC721(name, symbol) {
        withdrawAddress = _withdrawAddress;
        // allocate first to community
    }

    function reservePresale(uint256 reserveAmount, bytes32[] memory whitelistProof) external payable {
        require(presaleAllowed, "Presale is disabled");
        require(reserveAmount > 0, "Must reserve at least one");
        require(ticketCounter.add(reserveAmount) <= maxTotalSupply, "Exceeds max supply");
        require(reservationPrice.mul(reserveAmount) <= msg.value, "Ether value sent is not correct");

        bytes32 addressBytes = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(whitelistProof, merkleRoot, addressBytes), "Invalid whitelist proof");

        uint256 walletReservedClaims = reservedPresaleClaims[_msgSender()];
        require(reserveAmount.add(walletReservedClaims) <= maxReservePresale, "Exceeds max presale allowed per wallet");

        // increase reserved amount
        reservedPresaleClaims[_msgSender()] = reserveAmount.add(walletReservedClaims);

        // increase reserved tickets count
        ticketCounter = ticketCounter.add(reserveAmount);
    }

    function reservePublic(uint256 reserveAmount) external payable {
        require(publicSaleAllowed, "Public sale is disabled");
        require(reserveAmount > 0, "Must reserve at least one");
        require(reserveAmount <= maxReservePerTransaction, "Exceeds max allowed per transaction");
        require(ticketCounter.add(reserveAmount) <= maxTotalSupply, "Exceeds max supply");
        require(reservationPrice.mul(reserveAmount) <= msg.value, "Ether value sent is not correct");

        uint256 walletReservedClaims = reservedPublicClaims[_msgSender()];
        require(reserveAmount.add(walletReservedClaims) <= maxReservePublic, "Exceeds max public allowed per wallet");

        // increase reserved amount
        reservedPublicClaims[_msgSender()] = reserveAmount.add(walletReservedClaims);

        // increase reserved tickets count
        ticketCounter = ticketCounter.add(reserveAmount);
    }

    function reservePrivate(uint256 reserveAmount, address reserveAddress) external onlyOwner {
        require(ticketCounter.add(reserveAmount) <= maxTotalSupply, "Exceeds max supply");

        // increase reserved amount
        reservedPublicClaims[reserveAddress] = reserveAmount.add(reservedPublicClaims[reserveAddress]);

        // increase reserved tickets count
        ticketCounter = ticketCounter.add(reserveAmount);
    }

    function claimPresale() external {
        require(presaleAllowed, "Presale is disabled");

        uint256 walletReservedPresaleClaims = reservedPresaleClaims[_msgSender()];
        uint256 walletPresaleClaimCount = presaleClaimCounts[_msgSender()];
        require(walletPresaleClaimCount < walletReservedPresaleClaims, "Nothing to claim");

        for (uint256 i = 0; i < walletReservedPresaleClaims.sub(walletPresaleClaimCount); i++) {
            uint256 mintIndex = totalSupply().add(1);
            presaleClaimCounts[_msgSender()] = presaleClaimCounts[_msgSender()].add(1);
            _safeMint(_msgSender(), mintIndex);
        }
    }

    // public sale means all claims are available, no need to check presale state
    function claimAll() external {
        require(publicClaimAllowed, "Public claim is disabled");

        uint256 walletReservedPresaleClaims = reservedPresaleClaims[_msgSender()];
        uint256 walletReservedPublicClaims = reservedPublicClaims[_msgSender()];

        uint256 walletPublicClaimCount = publicClaimCounts[_msgSender()];
        uint256 walletPresaleClaimCount = presaleClaimCounts[_msgSender()];

        uint256 totalReserved = walletReservedPublicClaims.add(walletReservedPresaleClaims);
        uint256 totalClaimed = walletPublicClaimCount.add(walletPresaleClaimCount);

        require(totalClaimed < totalReserved, "Nothing to claim");

        for (uint256 i = 0; i < walletReservedPresaleClaims.sub(walletPresaleClaimCount); i++) {
            uint256 mintIndex = totalSupply().add(1);
            presaleClaimCounts[_msgSender()] = presaleClaimCounts[_msgSender()].add(1);
            _safeMint(_msgSender(), mintIndex);
        }

        for (uint256 i = 0; i < walletReservedPublicClaims.sub(walletPublicClaimCount); i++) {
            uint256 mintIndex = totalSupply().add(1);
            publicClaimCounts[_msgSender()] = publicClaimCounts[_msgSender()].add(1);
            _safeMint(_msgSender(), mintIndex);
        }
    }

    function setReservationPrice(uint256 _price) external onlyOwner {
        reservationPrice = _price;
    }

    function setMaxTotalSupply(uint256 _maxValue) external onlyOwner {
        maxTotalSupply = _maxValue;
    }

    function setMaxReservePresale(uint256 _maxValue) external onlyOwner {
        maxReservePresale = _maxValue;
    }

    function setMaxReservePublic(uint256 _maxValue) external onlyOwner {
        maxReservePublic = _maxValue;
    }

    function setPresaleAllowed(bool _allowed) external onlyOwner {
        presaleAllowed = _allowed;
    }

    function setPublicSaleAllowed(bool _allowed) external onlyOwner {
        publicSaleAllowed = _allowed;
    }

    function setPublicClaimAllowed(bool _allowed) external onlyOwner {
        publicClaimAllowed = _allowed;
    }

    function setMaxReservePerTransaction(uint256 _maxValue) external onlyOwner {
        maxReservePerTransaction = _maxValue;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Token not owned or approved");
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        require(withdrawAddress != address(0), "Withdraw address not set");

        uint256 contractBalance = address(this).balance;
        payable(withdrawAddress).transfer(contractBalance);
    }


    function setWithdrawAddress(address _newWithdrawAddress) external onlyOwner {
        withdrawAddress = _newWithdrawAddress;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        require(!provenanceHashLocked, "Provenance hash already locked");

        provenanceHash = _provenanceHash;
    }

    function lockProvenanceHash() external onlyOwner {
        require(!provenanceHashLocked, "Provenance hash already locked");

        provenanceHashLocked = true;
    }

    function getAvailableClaims(address walletAddress) external view returns (uint256) {
        uint256 walletReservedPresaleClaims = reservedPresaleClaims[walletAddress];
        uint256 walletReservedPublicClaims = reservedPublicClaims[walletAddress];

        uint256 walletPublicClaimCount = publicClaimCounts[walletAddress];
        uint256 walletPresaleClaimCount = presaleClaimCounts[walletAddress];

        uint256 totalReserved = walletReservedPublicClaims.add(walletReservedPresaleClaims);
        uint256 totalClaimed = walletPublicClaimCount.add(walletPresaleClaimCount);

        return totalReserved.sub(totalClaimed);
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}
