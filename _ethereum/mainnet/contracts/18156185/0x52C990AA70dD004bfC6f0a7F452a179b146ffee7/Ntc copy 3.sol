// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define the ERC-721 interface to interact with the ownerOf function
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Signet {
    // Mapping to store autographs: NFT address => NFT ID => signer address => IPFS hash
    mapping(address => mapping(uint256 => mapping(address => string)))
        public autographs;
    mapping(address => mapping(uint256 => mapping(address => uint))) public Bid;
    mapping(address => mapping(uint256 => mapping(address => uint)))
        public SigBid;
    mapping(address => BidStruct[]) public Bider;
    mapping(address => uint256) public Bids;
    mapping(address => uint256) public SigBids;

    // Mapping to store custom set of signatures to show for an NFT: NFT address => NFT ID => array of signer addresses
    mapping(address => mapping(uint256 => address[])) public shownSigners;
    // Mapping to store a list of signers for each NFT: NFT address => NFT ID => array of signer addresses
    mapping(address => mapping(uint256 => address[])) public nftSigners;
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public hasSigned;
    address public feeControl = 0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5;
    address public feeAddrs = 0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5;
    IERC20 public Sigs;
    // Define the struct
    struct BidStruct {
        address NFT;
        uint256 ID;
        uint256 Amount;
        uint256 SigAmount;
    }
    event NFTSigned(
        address indexed nftAddress,
        uint256 indexed nftId,
        address indexed signer,
        string ipfsHash
    );
    event Bided(
        address indexed nftAddress,
        uint256 indexed nftId,
        address indexed signer,
        uint value,
        uint SigAmount
    );
    event Claimed(
        address indexed nftAddress,
        uint256 indexed nftId,
        address indexed signer,
        uint value
    );
    event ClaimedSig(
        address indexed nftAddress,
        uint256 indexed nftId,
        address indexed signer,
        uint value
    );
    event SignaturesSet(
        address indexed nftAddress,
        uint256 indexed nftId,
        address[] signers
    );

    function signNFT(
        address nftAddress,
        uint256 nftId,
        string memory ipfsHash
    ) external {
        require(bytes(ipfsHash).length > 0, "Invalid IPFS hash");

        // Store the IPFS hash against the NFT and signer's address
        autographs[nftAddress][nftId][msg.sender] = ipfsHash;
        if (hasSigned[nftAddress][nftId][msg.sender] == false) {
            hasSigned[nftAddress][nftId][msg.sender] = true;
            nftSigners[nftAddress][nftId].push(msg.sender);
        }
        if (Bid[nftAddress][nftId][msg.sender] > 0) {
            uint amount = Bid[nftAddress][nftId][msg.sender];
            Bid[nftAddress][nftId][msg.sender] = 0;
            payable(feeAddrs).transfer((amount * 20) / 100);
            payable(msg.sender).transfer((amount * 80) / 100);
            emit Claimed(nftAddress, nftId, msg.sender, amount);
        }
        if (SigBid[nftAddress][nftId][msg.sender] > 0) {
            uint amount = SigBid[nftAddress][nftId][msg.sender];
            SigBid[nftAddress][nftId][msg.sender] = 0;
            Sigs.transfer(msg.sender, amount);
            emit ClaimedSig(nftAddress, nftId, msg.sender, amount);
        }
        emit NFTSigned(nftAddress, nftId, msg.sender, ipfsHash);
    }

    function setSignaturesToShow(
        address nftAddress,
        uint256 nftId,
        address[] memory signers
    ) external {
        IERC721 nftContract = IERC721(nftAddress);

        require(
            nftContract.ownerOf(nftId) == msg.sender,
            "Caller is not the owner of the NFT"
        );

        shownSigners[nftAddress][nftId] = signers;

        emit SignaturesSet(nftAddress, nftId, signers);
    }

    function setAddrs(address addrs, uint addrT) external {
        require(feeControl == msg.sender, "Caller is not the owner");
        if (addrT == 0) {
            feeAddrs = addrs;
        } else if (addrT == 1) {
            feeControl = addrs;
        } else if (addrT == 2) {
            require(Sigs == IERC20(address(0)), "");
            Sigs = IERC20(addrs);
        }
    }

    function unBid(
        address nftAddress,
        uint256 nftId,
        address signers
    ) external {
        IERC721 nftContract = IERC721(nftAddress);
        require(
            nftContract.ownerOf(nftId) == msg.sender,
            "Caller is not the owner of the NFT"
        );
        uint amount = Bid[nftAddress][nftId][signers];
        Bid[nftAddress][nftId][signers] = 0;
        payable(msg.sender).transfer(amount);
        uint Sigamount = SigBid[nftAddress][nftId][signers];
        SigBid[nftAddress][nftId][signers] = 0;
        Sigs.transfer(msg.sender, Sigamount);
    }

    function BidForSignet(
        address nftAddress,
        uint256 nftId,
        address signers,
        uint SigAmount
    ) external payable {
        require(
            msg.value >= 0.01 ether || SigAmount >= 20 ether,
            "Not enough Bided"
        );
        Bid[nftAddress][nftId][signers] += msg.value;
        SigBid[nftAddress][nftId][signers] += SigAmount;
        Sigs.transferFrom(msg.sender, address(this), SigAmount);
        BidStruct memory newBid = BidStruct({
            NFT: nftAddress,
            ID: nftId,
            Amount: msg.value,
            SigAmount: SigAmount
        });
        Bider[signers].push(newBid);
        Bids[signers]++;
        emit Bided(nftAddress, nftId, signers, msg.value, SigAmount);
    }

    // Function to retrieve a custom set of signatures set by the NFT owner
    function getShownSignatures(
        address nftAddress,
        uint256 nftId
    ) external view returns (address[] memory) {
        return shownSigners[nftAddress][nftId];
    }

    // Function to retrieve autographs for a specific NFT
    function getShownAutographs(
        address nftAddress,
        uint256 nftId
    ) external view returns (address[] memory, string[] memory) {
        address[] memory signers = shownSigners[nftAddress][nftId];
        if (signers.length != 0) {
            string[] memory hashes = new string[](signers.length);

            for (uint256 i = 0; i < signers.length; i++) {
                hashes[i] = autographs[nftAddress][nftId][signers[i]];
            }
            return (signers, hashes);
        } else {
            address[] memory sigs = nftSigners[nftAddress][nftId];
            string[] memory hashes = new string[](sigs.length);

            for (uint256 i = 0; i < sigs.length; i++) {
                hashes[i] = autographs[nftAddress][nftId][sigs[i]];
            }

            return (sigs, hashes);
        }
    }

    // Function to retrieve an autograph for a specific NFT by a specific signer
    function getAutograph(
        address nftAddress,
        uint256 nftId,
        address signer
    ) external view returns (string memory) {
        return autographs[nftAddress][nftId][signer];
    }

    // Function to retrieve all autographs for a specific NFT
    function getAllAutographs(
        address nftAddress,
        uint256 nftId
    ) external view returns (address[] memory, string[] memory) {
        address[] memory signers = nftSigners[nftAddress][nftId];
        string[] memory hashes = new string[](signers.length);

        for (uint256 i = 0; i < signers.length; i++) {
            hashes[i] = autographs[nftAddress][nftId][signers[i]];
        }

        return (signers, hashes);
    }
}
