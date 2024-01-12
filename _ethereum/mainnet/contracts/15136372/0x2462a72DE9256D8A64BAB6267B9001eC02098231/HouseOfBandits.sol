// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./MerkleProof.sol";
import "./Strings.sol";

import "./ERC1155Base.sol";
import "./EquitySplitter.sol";

contract HouseOfBandits is ERC1155Base, EquitySplitter {
    uint8 constant MASTER = 0;
    uint8 constant HOUSE = 1;

    uint16 constant MAX_SUPPLY_MASTER = 1000;
    uint16 constant MAX_SUPPLY_HOUSE = 3500;

    uint256 public ogMintStartTime;
    uint256 public ogMintEndTime;
    uint256 public alphalistMintStartTime;
    uint256 public alphalistMintEndTime;
    uint256 public publicRaffleMintStartTime;
    uint256 public publicRaffleMintEndTime;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        bytes32 _merkleRoot
    ) ERC1155(_uri) MintingBase(1, 0.123 ether, _merkleRoot) {
        name_ = _name;
        symbol_ = _symbol;
    }

    function setMintingWindows(
        uint256 _ogMintStartTime,
        uint256 _ogMintEndTime,
        uint256 _alphalistMintStartTime,
        uint256 _alphalistMintEndTime,
        uint256 _publicSaleMintStartTime,
        uint256 _publicSaleMintEndTime
    ) external onlyOwner {
        require(
            _publicSaleMintStartTime > _alphalistMintStartTime &&
                _alphalistMintStartTime > _ogMintStartTime &&
                _ogMintEndTime > _ogMintStartTime &&
                _alphalistMintEndTime > _alphalistMintStartTime &&
                _publicSaleMintEndTime > _publicSaleMintStartTime,
            "Invalid minting windows"
        );

        ogMintStartTime = _ogMintStartTime;
        ogMintEndTime = _ogMintEndTime;
        alphalistMintStartTime = _alphalistMintStartTime;
        alphalistMintEndTime = _alphalistMintEndTime;
        publicRaffleMintStartTime = _publicSaleMintStartTime;
        publicRaffleMintEndTime = _publicSaleMintEndTime;
    }

    function teamMint(
        address _address,
        uint16 _amountMaster,
        uint16 _amountHouse
    ) external onlyOwner whenNotPaused {
        require(
            totalSupply(HOUSE) + _amountHouse <= MAX_SUPPLY_HOUSE &&
                totalSupply(MASTER) + _amountMaster <= MAX_SUPPLY_MASTER,
            "Max supply reached"
        );

        _mint(_address, MASTER, _amountMaster, "");
        _mint(_address, HOUSE, _amountHouse, "");
    }

    function ogMint(
        uint8 _amountMaster,
        uint8 _amountHouse,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        whenNotPaused
        mintingIsOpen(ogMintStartTime, ogMintEndTime, "OG")
    {
        _mintTokens(_amountMaster, _amountHouse, 2, 3, _merkleProof);
    }

    function alphalistMint(
        uint8 _amountMaster,
        uint8 _amountHouse,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        whenNotPaused
        mintingIsOpen(alphalistMintStartTime, alphalistMintEndTime, "Alphalist")
    {
        _mintTokens(_amountMaster, _amountHouse, 2, 2, _merkleProof);
    }

    function publicRaffleMint(
        uint8 _amountMaster,
        uint8 _amountHouse,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        whenNotPaused
        mintingIsOpen(
            publicRaffleMintStartTime,
            publicRaffleMintEndTime,
            "Public Raffle"
        )
    {
        _mintTokens(_amountMaster, _amountHouse, 1, 2, _merkleProof);
    }

    function _mintTokens(
        uint8 _amountMaster,
        uint8 _amountHouse,
        uint8 _maxAmountHouseAllowed,
        uint8 _maxTotalAmountAllowed,
        bytes32[] calldata _merkleProof
    ) private nonReentrant limitTxs onlyAllowList(_merkleProof) {
        uint256 totalAmount = _amountMaster + _amountHouse;
        require(_amountMaster <= 1, "Too many Master Keys");
        require(_amountHouse <= _maxAmountHouseAllowed, "Too many House Keys");
        require(!(totalAmount == 0), "Invalid amount of keys");
        require(
            totalAmount <= _maxTotalAmountAllowed,
            "Invalid amount of keys"
        );
        require(
            totalSupply(HOUSE) + _amountHouse <= MAX_SUPPLY_HOUSE &&
                totalSupply(MASTER) + _amountMaster <= MAX_SUPPLY_MASTER,
            "Max supply reached"
        );
        require(
            msg.value == totalAmount * mintPrice,
            "Invalid amount of funds sent"
        );

        if (_amountMaster > 0) {
            _mintToken(MASTER, _amountMaster);
        }

        if (_amountHouse > 0) {
            _mintToken(HOUSE, _amountHouse);
        }

        mintTxs[msg.sender] += 1;
    }

    function _mintToken(uint8 _tokenId, uint8 _amount) private {
        _mint(msg.sender, _tokenId, _amount, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "Token does not exist");

        return
            string(
                abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json")
            );
    }
}
