// SPDX-License-Identifier: MIT

//       _______  _______  ______             _
//      (  ____ \(  ___  )(  __  \           / )
//      | (    \/| (   ) || (  \  )      _  / /
//      | (_____ | (___) || |   ) |     (_)( (
//      (_____  )|  ___  || |   | |        | |
//            ) || (   ) || |   ) |      _ ( (
//      /\____) || )   ( || (__/  )     (_) \ \
//      \_______)|/     \|(______/           \_)

pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC721Receiver.sol";
import "Ownable.sol";
import "ERC721Enumerable.sol";
import "ERC721Royalty.sol";


contract SAD is ERC721, IERC721Receiver, Ownable, ERC721Enumerable, ERC721Royalty {

    bool private _areWeReady = false;

    uint256 public availableTokens = TOTAL_SADS - TOTAL_SADS_FOR_MINT - _RESERVE;

    address public badContractAddress;

    mapping(uint256 => uint256) public bredCount;

    uint256 public constant MAX_SAD_PURCHASE = 5;

    mapping(uint256 => uint256) public _parents;

    string public constant PROVENANCE = "948c53a9e992089e7fda8770f18ffa4ae1f18bca1a4ae2c0871cc42f95608a07";

    uint256 private constant _RESERVE = 20;

    uint256 public constant SAD_PRICE = 42000000000000000; // Wei = 0.042 ETH

    uint256 private _sadFemaleClaimIndex;

    uint256 private _sadMaleClaimIndex;

    uint256 private _sadFemaleMintIndex;

    uint256 private _sadMaleMintIndex;

    uint256 public constant SPEED_UP_PRICE_SEC = 34722222222;

    mapping(address => uint256[]) private _stakerToTokens;

    mapping(uint256 => mapping(address => uint256)) private _stakeTimes;

    mapping(uint256 => uint256) private _tokenSales;

    uint256 public constant TOTAL_SADS = 7777;

    uint256 public constant TOTAL_SADS_FOR_MINT = 3333;

    constructor() ERC721("SAD Society", "SAD") {}

    function burnSads(uint256[5] memory _tokenIdList)
    external returns (bool) {
        require(msg.sender == badContractAddress, "Sender is not BAD contract");
        _burn(_tokenIdList[0]);
        _burn(_tokenIdList[1]);
        _burn(_tokenIdList[2]);
        _burn(_tokenIdList[3]);
        _burn(_tokenIdList[4]);
        return true;
    }

    function cancelStake(uint256 _tokenId1, uint256 _tokenId2) external {
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        require(_stakeTimes[concat][msg.sender] != 0, "Selected tokens are not staked or you are not the staker");
        _safeTransfer(address(this), msg.sender, _tokenId1, "");
        _safeTransfer(address(this), msg.sender, _tokenId2, "");
        delete _stakeTimes[concat][msg.sender];
        _removeTokenIdFromArray(_stakerToTokens[msg.sender], _tokenId1, _tokenId2);
        availableTokens++;
    }

    function claimBreed(uint256 _tokenId1, uint256 _tokenId2) external returns (uint256) {
        bool senderIsStaker = false;
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        for (uint256 i = 0; i < _stakerToTokens[msg.sender].length; i++) {
            if (_stakerToTokens[msg.sender][i] == concat) {
                senderIsStaker = true;
                break;
            }
        }
        require(senderIsStaker, "Selected tokens are not staked or you are not the staker");
        require(getRemainingBreedTime(_tokenId1, _tokenId2) == 0, "Breed time has not finished yet");
        _safeTransfer(address(this), msg.sender, _tokenId1, "");
        _safeTransfer(address(this), msg.sender, _tokenId2, "");
        uint256 bredToken = _safeClaimSad(msg.sender);
        bredCount[_tokenId1]++;
        bredCount[_tokenId2]++;
        _parents[bredToken] = concat;
        delete _stakeTimes[concat][msg.sender];
        _removeTokenIdFromArray(_stakerToTokens[msg.sender], _tokenId1, _tokenId2);
        return bredToken;
    }

    function stakeForBreed(uint256 _tokenId1, uint256 _tokenId2) external {
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        uint256 parents1 = _parents[_tokenId1];
        uint256 parents2 = _parents[_tokenId2];
        require(availableTokens > 0, "There are currently no more available tokens left. That might change if a staker cancels their stake");
        require(((_tokenId1 < 3889 && _tokenId2 >= 3889) || (_tokenId1 >= 3889 && _tokenId2 < 3889)), "You can only breed a male and a female SAD together");
        require(ownerOf(_tokenId1) == msg.sender && ownerOf(_tokenId2) == msg.sender, "You are not the owner of the requested tokens");
        if (!(parents1 / 10000 == 0 && parents2 / 10000 == 0)) {
            require(
                parents1 / 10000 != parents2 / 10000 &&
                parents1 % 10000 != parents2 % 10000 &&
                _tokenId1 != parents2 / 10000 &&
                _tokenId1 != parents2 % 10000 &&
                _tokenId2 != parents1 / 10000 &&
                _tokenId2 != parents1 % 10000,
                "You cannot breed siblings/half-siblings together or children with their parents"
            );
        }
        _safeTransfer(msg.sender, address(this), _tokenId1, "");
        _safeTransfer(msg.sender, address(this), _tokenId2, "");
        _stakeTimes[concat][msg.sender] = block.timestamp;
        _stakerToTokens[msg.sender].push(concat);
        availableTokens--;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external view override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function flipReadyState() public onlyOwner {
        _areWeReady = !_areWeReady;
    }

    function instantBreed(uint256 _tokenId1, uint256 _tokenId2) public payable returns (uint256) {
        bool senderIsStaker = false;
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        for (uint256 i = 0; i < _stakerToTokens[msg.sender].length; i++) {
            if (_stakerToTokens[msg.sender][i] == concat) {
                senderIsStaker = true;
                break;
            }
        }
        require(senderIsStaker, "Selected tokens are not staked or you are not the staker");
        uint256 price = getSpeedUpPrice(_tokenId1, _tokenId2);
        require(msg.value >= price, "Ether value sent is not correct");
        _safeTransfer(address(this), msg.sender, _tokenId1, "");
        _safeTransfer(address(this), msg.sender, _tokenId2, "");
        uint256 bredToken = _safeClaimSad(msg.sender);
        bredCount[_tokenId1]++;
        bredCount[_tokenId2]++;
        _parents[bredToken] = concat;
        delete _stakeTimes[concat][msg.sender];
        _removeTokenIdFromArray(_stakerToTokens[msg.sender], _tokenId1, _tokenId2);
        return bredToken;
    }

    function mintSad(uint256 _numberOfTokens) public payable returns (uint256[] memory) {
        require(saleIsActive(), "Sale not active");
        require(
            _sadMaleMintIndex + _sadFemaleMintIndex + _numberOfTokens <= TOTAL_SADS_FOR_MINT,
            "Purchase would exceed max supply of tokens"
        );
        require(
            _numberOfTokens <= MAX_SAD_PURCHASE,
            "Exceeded max token purchase"
        );
        require(
            SAD_PRICE * _numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        uint256[] memory mintedTokens = new uint256[](_numberOfTokens);

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 mintedToken = _safeMintSad(msg.sender);
            mintedTokens[i] = mintedToken;
        }
        return mintedTokens;
    }

    function reserveSads() public onlyOwner {
        for (uint256 i = 0; i < _RESERVE / 2; i++) {
            _safeMint(msg.sender, i);
            _safeMint(msg.sender, (TOTAL_SADS / 2) + 1 + i);
        }
    }

    function setBadContractAddress(address _address) public onlyOwner {
        badContractAddress = _address;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function bred() public view returns (uint256) {
        return _sadMaleClaimIndex + _sadFemaleClaimIndex;
    }

    function checkForBreed(uint256 _tokenId1, uint256 _tokenId2) public view returns (uint256 time, uint256 price) {
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        uint256 parents1 = _parents[_tokenId1];
        uint256 parents2 = _parents[_tokenId2];
        require(availableTokens > 0, "There are currently no more available tokens left. That might change if a staker cancels their stake");
        require(((_tokenId1 < 3889 && _tokenId2 >= 3889) || (_tokenId1 >= 3889 && _tokenId2 < 3889)), "You can only breed a male and a female SAD together");
        require(ownerOf(_tokenId1) == msg.sender && ownerOf(_tokenId2) == msg.sender, "You are not the owner of the requested tokens");
        if (!(parents1 / 10000 == 0 && parents2 / 10000 == 0)) {
            require(
                parents1 / 10000 != parents2 / 10000 &&
                parents1 % 10000 != parents2 % 10000 &&
                _tokenId1 != parents2 / 10000 &&
                _tokenId1 != parents2 % 10000 &&
                _tokenId2 != parents1 / 10000 &&
                _tokenId2 != parents1 % 10000,
                "You cannot breed siblings/half-siblings together or children with their parents"
            );
        }
        uint256 bredCount1 = bredCount[_tokenId1];
        uint256 bredCount2 = bredCount[_tokenId2];
        uint256 maxCount;
        if (bredCount1 > bredCount2) {
            maxCount = bredCount1;
        } else {
            maxCount = bredCount2;
        }
        uint256 breedTime = 200;
        for (uint256 i = 1; i < maxCount + 1; i++) {
            breedTime = breedTime * 161;
        }
        breedTime = breedTime / (100 ** (maxCount + 1));
        breedTime = breedTime * (1 weeks);
        uint256 price = breedTime * SPEED_UP_PRICE_SEC;
        return (breedTime, price);
    }

    function getParents(uint256 _tokenId) public view returns (uint256, uint256) {
        uint256 parents_ = _parents[_tokenId];
        uint256 mother = parents_ / 10000;
        uint256 father = parents_ % 10000;
        return (mother, father);
    }

    function getRemainingBreedTime(uint256 _tokenId1, uint256 _tokenId2) public view returns (uint256) {
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        require(_stakeTimes[concat][msg.sender] != 0, "Selected tokens are not staked or you are not the staker");
        uint256 bredCount1 = bredCount[_tokenId1];
        uint256 bredCount2 = bredCount[_tokenId2];
        uint256 maxCount;
        if (bredCount1 > bredCount2) {
            maxCount = bredCount1;
        } else {
            maxCount = bredCount2;
        }
        uint256 breedTime = 200;
        for (uint256 i = 1; i < maxCount + 1; i++) {
            breedTime = breedTime * 161;
        }
        breedTime = breedTime / (100 ** (maxCount + 1));
        breedTime = breedTime * (1 weeks);
        uint256 stakedAt = _stakeTimes[concat][msg.sender];
        uint256 dueTime = stakedAt + breedTime;
        if (dueTime > block.timestamp) {
            return dueTime - block.timestamp;
        } else {
            return 0;
        }
    }

    function getSpeedUpPrice(uint256 _tokenId1, uint256 _tokenId2) public view returns (uint256) {
        uint256 remainingTime = getRemainingBreedTime(_tokenId1, _tokenId2);
        uint256 price = remainingTime * SPEED_UP_PRICE_SEC;
        return price;
    }

    function getStakedTokens() public view returns (uint256[] memory) {
        uint256 stakedCount = _stakerToTokens[msg.sender].length;
        uint256[] memory stakedTokens = new uint256[](stakedCount * 2);
        for (uint256 i = 0; i < stakedCount; i++) {
            stakedTokens[i * 2] = (_stakerToTokens[msg.sender][i] / 10000);
            stakedTokens[(i * 2) + 1] = (_stakerToTokens[msg.sender][i] % 10000);
        }
        return stakedTokens;
    }

    function minted() public view returns (uint256) {
        return _sadMaleMintIndex + _sadFemaleMintIndex;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        uint256 percentage;

        uint256 saleCount = _tokenSales[_tokenId];

        if (saleCount == 0) {
            percentage = 100;
        } else if (saleCount < 8) {
            percentage = 120 ** saleCount / 100 ** (saleCount - 1);
        } else {
            percentage = 420;
        }

        uint256 royaltyAmount = (_salePrice * percentage) / _feeDenominator();

        return (owner(), royaltyAmount);
    }

    function saleIsActive() public view returns (bool) {
        return (block.timestamp >= 1657220387) && _areWeReady;
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(_tokenId);
        _resetTokenRoyalty(_tokenId);
    }

    function _removeTokenIdFromArray(uint256[] storage _array, uint256 _tokenId1, uint256 _tokenId2) internal {
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; i++) {
            if (_array[i] == concat) {
                length--;
                if (i < length) {
                    _array[i] = _array[length];
                }
                _array.pop();
                break;
            }
        }
    }

    function _safeClaimSad(address _to) internal returns (uint256) {
        uint8 randomNumber = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        _sadMaleClaimIndex
                    )
                )
            ) % 2
        );

        if (randomNumber == 0) {
            if (_sadMaleClaimIndex <= TOTAL_SADS / 2) {
                _safeMint(_to, _sadMaleClaimIndex + TOTAL_SADS_FOR_MINT / 2 + 1 + _RESERVE / 2);
                _sadMaleClaimIndex = _sadMaleClaimIndex + 1;
                return _sadMaleClaimIndex + TOTAL_SADS_FOR_MINT / 2 + _RESERVE / 2;
            } else {
                _safeMint(
                    _to,
                    _sadFemaleClaimIndex + TOTAL_SADS / 2 + TOTAL_SADS_FOR_MINT / 2 + _RESERVE / 2 + 1
                );
                _sadFemaleClaimIndex = _sadFemaleClaimIndex + 1;
                return _sadFemaleClaimIndex + TOTAL_SADS / 2 + TOTAL_SADS_FOR_MINT / 2 + _RESERVE / 2;
            }
        } else {
            if (_sadFemaleMintIndex < TOTAL_SADS) {
                _safeMint(
                    _to,
                    _sadFemaleClaimIndex + TOTAL_SADS / 2 + TOTAL_SADS_FOR_MINT / 2 + _RESERVE / 2 + 1
                );
                _sadFemaleClaimIndex = _sadFemaleClaimIndex + 1;
                return _sadFemaleClaimIndex + TOTAL_SADS / 2 + TOTAL_SADS_FOR_MINT / 2 + _RESERVE / 2;
            } else {
                _safeMint(_to, _sadMaleClaimIndex + TOTAL_SADS_FOR_MINT / 2 + 1 + _RESERVE / 2);
                _sadMaleClaimIndex = _sadMaleClaimIndex + 1;
                return _sadMaleClaimIndex + TOTAL_SADS_FOR_MINT / 2 + _RESERVE / 2;
            }
        }
    }

    function _safeMintSad(address _to) internal returns (uint256) {
        uint8 randomNumber = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        _sadMaleMintIndex + _sadFemaleMintIndex
                    )
                )
            ) % 2
        );
        if (randomNumber == 0) {
            if (_sadMaleMintIndex < TOTAL_SADS_FOR_MINT / 2 + 1) {
                _safeMint(_to, _sadMaleMintIndex + _RESERVE / 2);
                _sadMaleMintIndex = _sadMaleMintIndex + 1;
                return _sadMaleMintIndex + _RESERVE / 2 - 1;

            } else {
                _safeMint(
                    _to,
                    _sadFemaleMintIndex + 1 + TOTAL_SADS / 2 + _RESERVE / 2
                );
                _sadFemaleMintIndex = _sadFemaleMintIndex + 1;
                return _sadFemaleMintIndex + 1 + TOTAL_SADS / 2 + _RESERVE / 2 - 1;
            }
        } else {
            if (_sadFemaleMintIndex < TOTAL_SADS_FOR_MINT / 2) {
                _safeMint(
                    _to,
                    _sadFemaleMintIndex + 1 + TOTAL_SADS / 2 + _RESERVE / 2
                );
                _sadFemaleMintIndex = _sadFemaleMintIndex + 1;
                return _sadFemaleMintIndex + 1 + TOTAL_SADS / 2 + _RESERVE / 2 - 1;
            } else {
                _safeMint(_to, _sadMaleMintIndex + _RESERVE / 2);
                _sadMaleMintIndex = _sadMaleMintIndex + 1;
                return _sadMaleMintIndex + _RESERVE / 2 - 1;
            }
        }
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        if (_from != address(this)) {
            _tokenSales[_tokenId]++;
        }
        super._transfer(_from, _to, _tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return "ipfs://bafybeib3kydb5waxxw4vq3tibfl4tptzfqikxjubxoqpxz7wxyltpeypee/";
    }
}
