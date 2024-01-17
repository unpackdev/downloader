// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract YoorHelper is Pausable, Ownable {
    mapping(address => mapping(uint256 => uint256)) public prices;
    mapping(bytes => uint256) offersData;

    function makeOffer(
        address _token,
        uint256 _tokenId,
        uint256 _type // 0 - offer, 1 - bid
    ) public payable whenNotPaused {
        offersData[abi.encodePacked(_token, _tokenId, msg.sender, _type)] = msg
            .value;
    }

    function getOfferDataOf(
        address _token,
        uint256 _tokenId,
        address _sender,
        uint256 _type
    ) public view returns (uint256) {
        return offersData[abi.encodePacked(_token, _tokenId, _sender, _type)];
    }

    function cancelOffer(
        address _token,
        uint256 _tokenId,
        uint256 _type
    ) public {
        require(
            offersData[abi.encodePacked(_token, _tokenId, msg.sender, _type)] >
                0,
            'No offer found'
        );
        uint256 amount = offersData[
            abi.encodePacked(_token, _tokenId, msg.sender, _type)
        ];
        delete offersData[
            abi.encodePacked(_token, _tokenId, msg.sender, _type)
        ];
        payable(msg.sender).transfer(amount);
    }

    function acceptOffer(
        address _token,
        uint256 _tokenId,
        address _sender,
        uint256 _type
    ) public {
        require(
            msg.sender == IERC721(_token).ownerOf(_tokenId),
            'Only owner can accept offer'
        );
        require(
            offersData[abi.encodePacked(_token, _tokenId, _sender, _type)] > 0,
            'No offer found'
        );
        require(
            address(this) == IERC721(_token).getApproved(_tokenId),
            'Not approved'
        );
        uint256 amount = offersData[
            abi.encodePacked(_token, _tokenId, _sender, _type)
        ];
        delete offersData[abi.encodePacked(_token, _tokenId, _sender, _type)];
        IERC721(_token).transferFrom(
            IERC721(_token).ownerOf(_tokenId),
            _sender,
            _tokenId
        );
        payable(IERC721(_token).ownerOf(_tokenId)).transfer(amount);
    }

    function putTokenOnSale(
        address _token,
        uint256 _tokenId,
        uint256 _price
    ) public whenNotPaused {
        require(
            msg.sender == IERC721(_token).ownerOf(_tokenId),
            'Only owner can update'
        );
        // IERC721(_token).approve(address(this), _tokenId);
        require(
            address(this) == IERC721(_token).getApproved(_tokenId),
            'Not approved'
        );
        prices[_token][_tokenId] = _price;
    }

    function removeTokenFromSale(address _token, uint256 _tokenId) public {
        require(
            msg.sender == IERC721(_token).ownerOf(_tokenId),
            'Only owner can update'
        );
        // require(
        //     address(this) == IERC721(_token).getApproved(_tokenId),
        //     'Not approved'
        // );
        delete prices[_token][_tokenId];
        // IERC721(_token).approve(address(0), _tokenId);
    }

    function buyToken(address _token, uint256 _tokenId) public payable {
        require(
            address(this) == IERC721(_token).getApproved(_tokenId),
            'Not approved'
        );
        require(prices[_token][_tokenId] != 0, 'Price not set for this token');
        require(
            msg.value == prices[_token][_tokenId],
            'Please send exact amount'
        );
        delete prices[_token][_tokenId];
        IERC721(_token).transferFrom(
            IERC721(_token).ownerOf(_tokenId),
            msg.sender,
            _tokenId
        );
    }

    // function withdraw() public onlyOwner {
    //     payable(msg.sender).transfer(address(this).balance);
    // }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
