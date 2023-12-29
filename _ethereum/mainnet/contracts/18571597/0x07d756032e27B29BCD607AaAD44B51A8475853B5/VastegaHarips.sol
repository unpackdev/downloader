// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./Owned.sol";

contract VastegaHarips is ERC721, Owned {
    using Strings for uint256;

    struct Stage {
        bool wlRequired;
        uint256 id;
        uint256 price;
        uint256 max_supply;
    }

    //// STORAGE ////

    // Metadata
    uint256 constant public MAX_SUPPLY = 5555;
    string private _baseURI = "https://vastega.io/meta/";

    // Presale
    Stage public stage;
    bool public salePaused;
    mapping(uint256 => mapping(address => bool)) public stageWlUsed; // stage.id => account => bool - one mint per stage
    address public operator;
    uint256 public supply;

    //// CONSTRUCTOR ////

    constructor(
        address operator_
    ) ERC721("Vastega: Harips", "HRPS") Owned(msg.sender) {
        operator = operator_;
    }

    //// ERC721 OVERRIDES ////

    function tokenURI(
        uint256 id_
    ) public view override returns (string memory) {
        return string.concat(_baseURI, id_.toString());
    }

    //// MINT ////

    function mint(
        address to_,
        uint256 amount_,
        bytes memory signature_
    ) public payable {

        require(!salePaused, "Vastega: Sale paused");
        require(msg.value >= stage.price*amount_, "Vastega: Wrong msg.value");
        require(supply+amount_ <= stage.max_supply, "Vastega: Stage supply overflow");

        if (stage.wlRequired) {
            require(!stageWlUsed[stage.id][to_], "Vastega: WL already used");
            stageWlUsed[stage.id][to_] = true;
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            _verifySignature(
                keccak256(abi.encodePacked(prefix, keccak256(abi.encodePacked(to_, amount_)))),
                signature_
            );
        }

        uint256 lastId_ = supply;
        for (uint256 i = 0; i < amount_; i++) {
            lastId_ += 1;
            _mint(to_, lastId_);
        }
        supply = lastId_;
    }

    //// ONLY OWNER ////

    function setBaseURI(
        string memory baseURI_
    ) public onlyOwner {
        _baseURI = baseURI_;
    }

    function setOperator(
        address operator_
    ) public onlyOwner {
        operator = operator_;
    }

    function setStage(
        bool wlRequired_,
        uint256 id_,
        uint256 price_,
        uint256 max_supply_
    ) public onlyOwner {
        require(max_supply_ <= MAX_SUPPLY, "Vastega: stage supply exceeds MAX_SUPPLY");
        stage = Stage(wlRequired_, id_, price_, max_supply_);
    }

    function switchSalePaused() public onlyOwner {
        salePaused = !salePaused;
    }

    function withdraw() public onlyOwner {
        (bool sent,) = owner.call{value: address(this).balance}("");
        require(sent);
    }

    //// PRIVATE ////

    function _verifySignature(
        bytes32 hash,
        bytes memory signature
    ) private view {
        require(signature.length == 65, "INVALID_SIGNATURE_LENGTH");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "INVALID_SIGNATURE_S_PARAMETER");
        require(v == 27 || v == 28, "INVALID_SIGNATURE_V_PARAMETER");

        require(ecrecover(hash, v, r, s) == operator, "INVALID_SIGNER");
    }

}
