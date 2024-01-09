// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Pausable.sol";
import "./Ownable.sol";

contract BillionaireNFT is Ownable, ERC721Pausable {
    //financial
    address payable receiver =
        payable(0x59eF96C6180A51ea71C735e24aa28637aa02a77f);

    uint256 public priceVIP = 0.08 ether;
    uint256 public priceWL = 0.14 ether;
    uint256 public pricePublic = 0.22 ether;

    //metadata
    string theBaseURI =
        "ipfs://QmQCuxBfgHRVdWBGg3Mxj7fUrwTziEK26WFf3PyUZ2ZMsS/";
    string theCtrURI;
    string public provenance;
    bool frozen;

    // nft reserves
    uint256 public currentTotal;

    uint256 public currentDrop;
    uint256 public currentVIP;
    uint256 public currentWL;
    uint256 public currentPublic;

    uint256 public maxSupply = 9786;
    uint256 public reserveDrop = 160;
    uint256 public reserveVIP = 190;
    uint256 public reserveWL = 2000;
    uint256 public reservePublic = 7436;

    //tickets
    address private _signerAddress = 0xF2717b1FA24EC624b0ad3FA01F46542e830DaDc4;
    mapping(uint256 => bool) nonceUsed;

    function withdraw() external {
        uint256 amount = address(this).balance;
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    constructor() ERC721("Billionaire Women NFTs", "BWN") {}

    //reserves
    function setReserves(
        uint256 drop,
        uint256 vip,
        uint256 wl,
        uint256 pub
    ) external onlyOwner {
        require(currentDrop <= drop, "Already airdropped more");
        require(currentVIP <= vip, "Already VIP minted more");
        require(currentWL <= wl, "Already WL minted more");
        require(currentPublic <= pub, "Already publicly minted more");
        require(drop + vip + wl + pub == maxSupply, "Reserves dont add up");
        reserveDrop = drop;
        reserveVIP = vip;
        reserveWL = wl;
        reservePublic = pub;
    }

    function setPrices(
        uint256 vip,
        uint256 wl,
        uint256 pub
    ) external onlyOwner {
        priceVIP = vip;
        priceWL = wl;
        pricePublic = pub;
    }

    //ticketing

    function replaceSigner(address signer) external onlyOwner {
        _signerAddress = signer;
    }

    function _checkTicket(
        address who,
        uint256 quanty,
        uint256 lvl,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        require(!nonceUsed[nonce], "Nonce already used");
        nonceUsed[nonce] = true;
        bytes32 payloadHash = keccak256(
            abi.encode(address(this), lvl, quanty, who, nonce)
        );
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash)
        );
        address actualSigner = ecrecover(messageHash, v, r, s);
        return actualSigner == _signerAddress;
    }

    function mintVIP(
        uint256 ticket,
        uint256 qnty,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        uint256 lvl = 1;
        require(currentTotal + qnty <= maxSupply, "Total reserve exceeded");
        require(currentVIP + qnty <= reserveVIP, "VIP reserve exceeded");
        require(priceVIP * qnty <= msg.value, "Insufficient funds send");
        bool validTicket = _checkTicket(msg.sender, qnty, lvl, ticket, v, r, s);
        require(validTicket, "Ticket invalid for VIP mint");

        currentVIP += qnty;
        _mint_NFT(msg.sender, qnty);
    }

    function mintWL(
        uint256 ticket,
        uint256 qnty,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        uint256 lvl = 2;
        require(currentTotal + qnty <= maxSupply, "Total reserve exceeded");
        require(currentWL + qnty <= reserveWL, "whitelist Reserve exceeded");
        require(priceWL * qnty <= msg.value, "Insufficient funds send");
        bool validTicket = _checkTicket(msg.sender, qnty, lvl, ticket, v, r, s);
        require(validTicket, "Ticket invalid for whitelist mint");

        currentWL += qnty;
        _mint_NFT(msg.sender, qnty);
    }

    function mintPublic(
        uint256 ticket,
        uint256 qnty,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        uint256 lvl = 3;
        require(currentTotal + qnty <= maxSupply, "Total reserve exceeded");
        require(
            currentPublic + qnty <= reservePublic,
            "Public Reserve exceeded"
        );
        require(pricePublic * qnty <= msg.value, "Insufficient funds send");
        bool validTicket = _checkTicket(msg.sender, qnty, lvl, ticket, v, r, s);
        require(validTicket, "Ticket invalid for public mint");

        currentPublic += qnty;
        _mint_NFT(msg.sender, qnty);
    }

    //airdrops
    function airdrop(address[] calldata winners, uint256[] calldata quanty)
        external
        onlyOwner
    {
        require(
            winners.length == quanty.length,
            "Mismatch of airdrop information"
        );
        for (uint256 i = 0; i < winners.length; i++) {
            require(
                currentDrop + quanty[i] <= reserveDrop,
                "Airdrop exhausted"
            );

            currentDrop += quanty[i];
            _mint_NFT(winners[i], quanty[i]);
        }
    }

    //metadata
    modifier isNotFrozen() {
        require(!frozen, "Metadata is frozen");
        _;
    }

    function freezeMeta() external onlyOwner {
        //Attention: Cannot be reversed
        frozen = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return theBaseURI;
    }

    function setBaseURI(string memory url) external onlyOwner isNotFrozen {
        theBaseURI = url;
    }

    function setCtrURI(string memory url) external onlyOwner isNotFrozen {
        theCtrURI = url;
    }

    function contractURI() public view returns (string memory) {
        return theCtrURI;
    }

    function setProvenance(string memory prov) external onlyOwner isNotFrozen {
        provenance = prov;
    }

    //minting
    function _mint_NFT(address who, uint256 howmany) internal {
        require(currentTotal + howmany <= maxSupply, "All NFTs minted");
        for (uint256 j = 0; j < howmany; j++) {
            _mint(who, currentTotal);
            currentTotal += 1;
        }
    }

    function emergencyHalt() external onlyOwner isNotFrozen {
        _pause();
    }

    function emergencyContinue() external onlyOwner {
        _unpause();
    }
}
