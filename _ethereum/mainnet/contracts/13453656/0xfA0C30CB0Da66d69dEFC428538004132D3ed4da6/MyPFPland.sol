// SPDX-License-Identifier: MIT
pragma solidity ^0.6.5;

import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ERC721.sol";

contract MyPFPland is ERC721Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter internal toyTokenIDs;
    CountersUpgradeable.Counter internal paintingTokenIDs;
    CountersUpgradeable.Counter internal statuetteTokenIDs;

    uint256 internal toyTokenIDBase;
    uint256 internal paintingTokenIDBase;
    uint256 internal statuetteTokenIDBase;

    address public _owner;
    bool public isOpenPayment;

    bool public isPausedClaimingToy;
    bool public isPausedClaimingPainting;
    bool public isPausedClaimingStatteute;

    mapping(address => uint256) internal addressToClaimedToy;
    mapping(address => uint256) internal addressToClaimedPainting;
    mapping(address => uint256) internal addressToClaimedStateutte;

    mapping(uint256 => bool) public oldTokenIDUsed;

    mapping(address => uint256) internal addressToMigratedCameo;
    mapping(address => uint256) internal addressToMigratedHonorary;
    
    mapping(address => uint256) internal addressToRoyalty;
    ERC721 blootNFT;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function initialize() initializer external {
        __ERC721_init("MyPFPland", "MyPFPland");
        _owner = msg.sender;

        toyTokenIDBase = 0;
        paintingTokenIDBase = 300;
        statuetteTokenIDBase = 400;
        blootNFT = ERC721(0x72541Ad75E05BC77C7A92304225937a8F6653372);
    }

    function claim(uint256 _category, uint256 _count) external payable {
        require(_category >= 1, "out of range");
        require(_category <= 3, "out of range");
        if (_category == 1)
            require(isPausedClaimingToy == false, "toy claiming is paused");
        if (_category == 2)
            require(isPausedClaimingPainting == false, "painting claiming is paused");
        if (_category == 3)
            require(isPausedClaimingStatteute == false, "statteute claiming is paused");
        
        uint256 totalDerivative = getTotalDerivative(msg.sender, _category);
        if (_category == 1)
            totalDerivative += addressToMigratedCameo[msg.sender];
        else if (_category == 2)
            totalDerivative += addressToMigratedHonorary[msg.sender];

        uint256 tokenID = 0;
        if (_category == 1)
            require(totalDerivative >= addressToClaimedToy[msg.sender] + _count, "already claimed all toys");
        else if (_category == 2)
            require(totalDerivative >= addressToClaimedPainting[msg.sender] + _count, "already claimed all paintings");
        else if (_category == 3)
            require(totalDerivative >= _count, "already claimed all statteutes");
    
        for (uint8 i = 0; i < _count; i++) {
            if (_category == 1) {
                toyTokenIDs.increment();
                tokenID = toyTokenIDs.current() + toyTokenIDBase;
            } else if (_category == 2) {
                paintingTokenIDs.increment();
                tokenID = paintingTokenIDs.current() + paintingTokenIDBase;
            } else if (_category == 3) {
                statuetteTokenIDs.increment();
                tokenID = statuetteTokenIDs.current() + statuetteTokenIDBase;
            }
            _safeMint(msg.sender, tokenID);
            _setTokenURI(tokenID, uint2str(tokenID));
        }

        if (_category == 1)
            addressToClaimedToy[msg.sender] += _count;
        else if (_category == 2)
            addressToClaimedPainting[msg.sender] += _count;

        // set oldTokenIDUsed true for those IDs already used
        if (totalDerivative > 0 && _category == 3) {
            for (uint8 i = 0; i < blootNFT.balanceOf(msg.sender); i++) {
                uint256 tokenId = blootNFT.tokenOfOwnerByIndex(msg.sender, i);
                if (tokenId <= 1484) {
                    oldTokenIDUsed[tokenId] = true;
                }
            }
        }
    }

    function airdrop(address[] calldata _claimList, uint256[] calldata _tokenIDs, uint256 _count) external onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            uint256 tokenID = 0;
            if (_tokenIDs[i] <= 300) {
                toyTokenIDs.increment();
                tokenID = toyTokenIDs.current() + toyTokenIDBase;

                addressToClaimedToy[_claimList[i]] += 1;
            } else if (_tokenIDs[i] <= 400) {
                paintingTokenIDs.increment();
                tokenID = paintingTokenIDs.current() + paintingTokenIDBase;

                addressToClaimedPainting[_claimList[i]] += 1;
            } else {
                statuetteTokenIDs.increment();
                tokenID = statuetteTokenIDs.current() + statuetteTokenIDBase;
            }
            _safeMint(_claimList[i], tokenID);
            _setTokenURI(tokenID, uint2str(tokenID));
            if (tokenID > 400) {
                for (uint256 j = 0; j < blootNFT.balanceOf(_claimList[i]); j++) {
                    uint256 tokenId = blootNFT.tokenOfOwnerByIndex(_claimList[i], j);
                    if (tokenId <= 1484)
                        oldTokenIDUsed[tokenId] = true;
                }
            }
        }
    }

    function getDerivativesToClaim(address _claimer, uint256 _category) external view returns(uint256) {
        uint256 remain = 0;
        if (_category < 1 || _category > 3)
            return remain;
        
        uint256 totalDerivative = getTotalDerivative(_claimer, _category);
        if (_category == 1) {
            totalDerivative += addressToMigratedCameo[_claimer];
            remain = totalDerivative - addressToClaimedToy[_claimer];
        }
        else if (_category == 2) {
            totalDerivative += addressToMigratedHonorary[_claimer];
            remain = totalDerivative - addressToClaimedPainting[_claimer];
        }
        else if (_category == 3) {
            remain = totalDerivative;
        }

        return remain;
    }

    function getTotalDerivative(address _claimer, uint256 _category) internal view returns(uint256) {
        uint256 result = 0;
        if (blootNFT.balanceOf(_claimer) == 0)
            return result;
        uint256 tokenIdMin;
        uint256 tokenIdMax;
        if (_category == 1) {
            tokenIdMin = 4790;
            tokenIdMax = 4962;
        } else if (_category == 2) {
            tokenIdMin = 4963;
            tokenIdMax = 5000;
        } else if (_category == 3) {
            tokenIdMin = 1;
            tokenIdMax = 1484;
        }

        for (uint256 i = 0; i < blootNFT.balanceOf(_claimer); i++) {
            uint256 tokenId = blootNFT.tokenOfOwnerByIndex(_claimer, i);
            if (tokenId >= tokenIdMin && tokenId <= tokenIdMax) {
                if (_category == 3) {
                    if (!oldTokenIDUsed[tokenId])
                        result++;
                }
                else
                    result++;
            }
        }

        return result;
    }

    function setPauseClaimingToy(bool _pauseClaimingToy) external onlyOwner {
        isPausedClaimingToy = _pauseClaimingToy;
    }

    function setPauseClaimingPainting(bool _pauseClaimingPainting) external onlyOwner {
        isPausedClaimingPainting = _pauseClaimingPainting;
    }

    function setPauseClaimingStatteute(bool _pauseClaimingStatteute) external onlyOwner {
        isPausedClaimingStatteute = _pauseClaimingStatteute;
    }

    function setBatchCameoWhitelist(address[] calldata _whitelist, uint256 _count) external onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            addressToMigratedCameo[_whitelist[i]] += 1;
        }
    }

    function setBatchHonoraryWhitelist(address[] calldata _whitelist, uint256 _count) external onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            addressToMigratedHonorary[_whitelist[i]] += 1;
        }
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        super._setBaseURI(_baseURI);
    }

    function setTokenURI(uint256 _tokenID, uint256 _tokenURI) external onlyOwner {
        super._setTokenURI(_tokenID, uint2str(_tokenURI));
    }

    function setTokenURIs(uint256[] calldata _tokenIDs, uint256[] calldata _tokenURIs, uint256 _count) external onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            super._setTokenURI(_tokenIDs[i], uint2str(_tokenURIs[i]));
        }
    }

    function openPayment(bool _open) external onlyOwner {
        isOpenPayment = _open;
    }

    function setBatchRoyalty(address[] calldata _people, uint256[] calldata _amount, uint256 _count) external onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            addressToRoyalty[_people[i]] = _amount[i];
        }
    }

    function setRoyalty(address _person, uint256 _amount) external onlyOwner {
        addressToRoyalty[_person] = _amount;
    }

    function royaltyOf(address _person) external view returns(uint256) {
        return addressToRoyalty[_person];
    }

    function withdraw() external onlyOwner {
        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success, "Failed to send");
    }

    function withdrawRoyalty() external {
        require(isOpenPayment == true, "Payment is closed");
        require(addressToRoyalty[msg.sender] > 0, "You don't have any royalties");
        require(address(this).balance >= addressToRoyalty[msg.sender], "Insufficient balance in the contract");
        require(msg.sender != address(0x0), "invalid caller");

        (bool success, ) = msg.sender.call{value: addressToRoyalty[msg.sender]}("");
        require(success, "Failed to send eth");
        addressToRoyalty[msg.sender] = 0;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}