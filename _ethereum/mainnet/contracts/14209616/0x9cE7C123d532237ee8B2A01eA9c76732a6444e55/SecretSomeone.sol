// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Secret Someone
pragma solidity 0.8.11;
//  ______    _____  _____  __ __      _____   _______      ______   _____     __    __    _____   _____     __   __    _____  
// / ____/\ /\_____\/\ __/\/_/\__/\  /\_____\/\_______)\   / ____/\ ) ___ (   /_/\  /\_\ /\_____\ ) ___ (   /_/\ /\_\ /\_____\ 
// ) ) __\/( (_____/) )__\/) ) ) ) )( (_____/\(___  __\/   ) ) __\// /\_/\ \  ) ) \/ ( (( (_____// /\_/\ \  ) ) \ ( (( (_____/ 
//  \ \ \   \ \__\ / / /  /_/ /_/_/  \ \__\    / / /        \ \ \ / /_/ (_\ \/_/ \  / \_\\ \__\ / /_/ (_\ \/_/   \ \_\\ \__\   
//  _\ \ \  / /__/_\ \ \_ \ \ \ \ \  / /__/_  ( ( (         _\ \ \\ \ )_/ / /\ \ \\// / // /__/_\ \ )_/ / /\ \ \   / // /__/_  
// )____) )( (_____\) )__/\)_) ) \ \( (_____\  \ \ \       )____) )\ \/_\/ /  )_) )( (_(( (_____\\ \/_\/ /  )_) \ (_(( (_____\ 
// \____\/  \/_____/\/___\/\_\/ \_\/ \/_____/  /_/_/       \____\/  )_____(   \_\/  \/_/ \/_____/ )_____(   \_\/ \/_/ \/_____/ 
                                                                                                                            

import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract SecretSomeone is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    uint256 public immutable COMPLIMENTARY_SOMEONES;
    uint256 public constant DISCOUNTED_PERIOD = 10 days;
    uint256 public constant DISCOUNTED_PRICE = 0.014 ether;
    uint256 public constant PRICE = 0.027 ether;
    uint256 public complimentaryPeriodEndedOn;
    Counters.Counter public secrets;

    constructor(uint256 _complimentary) ERC721("Secret Someone", "SSO") {
        COMPLIMENTARY_SOMEONES = _complimentary;
    }

    event SecretSealed(
        address indexed sender,
        address indexed receiver,
        uint256 senderTokenId,
        uint256 receiverTokenId
    );

    function sendSecret(address _receiver, string memory _ipfsHash)
        external
        payable
        whenNotPaused
    {
        if (secrets.current() / 2 + 1 > COMPLIMENTARY_SOMEONES) {
            if (
                block.timestamp <=
                complimentaryPeriodEndedOn + DISCOUNTED_PERIOD
            ) {
                require(
                    msg.value == DISCOUNTED_PRICE,
                    "Send exact discount price"
                );
            } else {
                require(msg.value == PRICE, "Send exact secret price");
            }
        } else {
            require(msg.value == 0, "Are you rich?");
        }
        require(_receiver != address(0), "Don't feel lonely");
        // send to secret someone
        secrets.increment();
        _mint(_receiver, secrets.current());
        _setTokenURI(secrets.current(), _ipfsHash);
        // mint the secret to yourself too
        secrets.increment();
        _mint(msg.sender, secrets.current());
        _setTokenURI(secrets.current(), _ipfsHash);
        if (COMPLIMENTARY_SOMEONES <= secrets.current() / 2 && complimentaryPeriodEndedOn == 0) {
            complimentaryPeriodEndedOn = block.timestamp;
        }
        emit SecretSealed(
            msg.sender,
            _receiver,
            secrets.current(),
            secrets.current() - 1
        );
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function togglePauseState() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            from == address(0) || to == address(0),
            "Passing secrets is bad manners"
        );
    }
}
