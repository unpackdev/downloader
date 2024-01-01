// D
//
// SPDX-License-Identifier: MIT
// Copyright Danturu, 2023

pragma solidity ^0.8.21;

contract F1 {
    event ArtpieceCreated(address indexed creator);
    event ArtpieceTransferred(address indexed oldOwner, address indexed newOwner);
    event BidAccepted(uint256 value, address indexed fromAddress, address indexed toAddress);
    event BidPlaced(uint256 value, address indexed fromAddress);
    event BidWithdrawn(uint256 value, address indexed fromAddress);
    event ListedForSale(uint256 value, address indexed fromAddress, address indexed toAddress);
    event SaleCanceled(uint256 value, address indexed fromAddress, address indexed toAddress);
    event SaleCompleted(uint256 value, address indexed fromAddress, address indexed toAddress);

    error FundsTransfer();
    error InsufficientFunds();
    error ListedForSaleToSpecificAddress();
    error NoBid();
    error NotForSale();
    error NotOwner();
    error NotRoyaltyRecipient();
    error NotYourBid();
    error NullAddress();
    error RoyaltyTooHigh();

    string public constant MANIFEST = (
        'D' '\n'
    );

    string public constant ARTPIECE = (
        'function setupAnimation(e){window.removeEventListener(e.type,setupAnimation,!1),(gl=getRenderingContext())&&(gl.enable(gl.SCISSOR_TEST),gl.clearColor(color[0],color[1],color[2],1),position=[0,gl.drawingBufferHeight],timer=setInterval(drawAnimation,17),drawAnimation())}function drawAnimation(){gl.scissor(position[0],position[1],size[0],size[1]),gl.clear(gl.COLOR_BUFFER_BIT),position[1]-=velocity,position[1]<0&&(position=[Math.random()*(gl.drawingBufferWidth-size[0]),gl.drawingBufferHeight],velocity=1+6*Math.random(),color=getRandomColor(),gl.clearColor(color[0],color[1],color[2],1))}function getRandomColor(){return[Math.random(),Math.random(),Math.random()]}function getRenderingContext(){var e=document.createElement("canvas");e.width=window.innerWidth*window.devicePixelRatio,e.height=window.innerHeight*window.devicePixelRatio,e.style.width="100%",e.style.backgroundColor="black",e.style.height="100%",document.body.append(e);var o=e.getContext("webgl")||e.getContext("experimental-webgl");return o?(o.viewport(0,0,o.drawingBufferWidth,o.drawingBufferHeight),o.clearColor(0,0,0,1),o.clear(o.COLOR_BUFFER_BIT),o):(document.querySelector("p").innerHTML="Failed to get WebGL context.Your browser or device may not support WebGL.",null)}window.addEventListener("load",setupAnimation,!1);var gl,position,color=getRandomColor(),size=[360,360],velocity=3;'
    );

    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert NotOwner();
        }

        _;
    }

    modifier onlyRoyaltyRecipient() {
        if (royaltyRecipient != msg.sender) {
            revert NotRoyaltyRecipient();
        }

        _;
    }

    struct Offer {
        bool active;
        uint256 value;
        address toAddress;
    }

    struct Bid {
        bool active;
        uint256 value;
        address fromAddress;
    }

    address public owner;

    Offer public currentOffer;

    Bid public currentBid;

    address public royaltyRecipient;

    uint256 public royaltyPercentage;

    mapping (address => uint256) public pendingWithdrawals;

    constructor(uint256 _royaltyPercentage) {
        if (_royaltyPercentage >= 100) {
            revert RoyaltyTooHigh();
        }

        owner = msg.sender;
        royaltyRecipient = msg.sender;
        royaltyPercentage = _royaltyPercentage;

        emit ArtpieceCreated(msg.sender);
    }

    function name() public view virtual returns (string memory) {
        return 'F1';
    }

    function symbol() public view virtual returns (string memory) {
        return 'D';
    }

    function artpiece() public view virtual returns (string memory) {
        return string.concat(
            '<!DOCTYPE html>'
            '<html>'
                '<head>'
                    '<title>', 'F1', '</title>'

                    '<style>body{background:#969696;margin:0;padding:0;overflow:hidden;}</style>'
                '</head>'

                '<body>'
                    '<script type="text/javascript">',
                        ARTPIECE,
                    '</script>'
                '</body>'
            '</html>'
        );
    }

    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];

        pendingWithdrawals[msg.sender] = 0;

        _sendFunds(amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert NullAddress();
        }

        _transferOwnership(newOwner);

        if (currentBid.fromAddress == newOwner) {
            uint256 amount = currentBid.value;

            currentBid = Bid({ active: false, value: 0, fromAddress: address(0) });

            pendingWithdrawals[newOwner] += amount;
        }

        if (currentOffer.active) {
            currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });
        }
    }

    function listForSale(uint256 salePriceInWei) public onlyOwner {
        currentOffer = Offer({ active: true, value: salePriceInWei, toAddress: address(0) });

        emit ListedForSale(salePriceInWei, msg.sender, address(0));
    }

    function listForSaleToAddress(uint256 salePriceInWei, address toAddress) public onlyOwner {
        currentOffer = Offer({ active: true, value: salePriceInWei, toAddress: toAddress });

        emit ListedForSale(salePriceInWei, msg.sender, toAddress);
    }

    function cancelFromSale() public onlyOwner {
        Offer memory oldOffer = currentOffer;

        currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });

        emit SaleCanceled(oldOffer.value, msg.sender, oldOffer.toAddress);
    }

    function buyNow() public payable {
        if (!currentOffer.active) {
            revert NotForSale();
        }

        if (currentOffer.toAddress != address(0) && currentOffer.toAddress != msg.sender) {
            revert ListedForSaleToSpecificAddress();
        }

        if (msg.value != currentOffer.value) {
            revert InsufficientFunds();
        }

        currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });

        uint256 royaltyAmount = _calcRoyalty(msg.value);

        pendingWithdrawals[owner] += msg.value - royaltyAmount;
        pendingWithdrawals[royaltyRecipient] += royaltyAmount;

        emit SaleCompleted(msg.value, owner, msg.sender);

        _transferOwnership(msg.sender);
    }

    function placeBid() public payable {
        if (msg.value <= currentBid.value) {
            revert InsufficientFunds();
        }

        if (currentBid.value > 0) {
            pendingWithdrawals[currentBid.fromAddress] += currentBid.value;
        }

        currentBid = Bid({ active: true, value: msg.value, fromAddress: msg.sender });

        emit BidPlaced(msg.value, msg.sender);
    }

    function acceptBid() public onlyOwner {
        if (!currentBid.active) {
            revert NoBid();
        }

        uint256 amount = currentBid.value;
        address bidder = currentBid.fromAddress;

        currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });
        currentBid = Bid({ active: false, value: 0, fromAddress: address(0) });

        uint256 royaltyAmount = _calcRoyalty(amount);

        pendingWithdrawals[owner] += amount - royaltyAmount;
        pendingWithdrawals[royaltyRecipient] += royaltyAmount;

        emit BidAccepted(amount, owner, bidder);

        _transferOwnership(bidder);
    }

    function withdrawBid() public {
        if (msg.sender != currentBid.fromAddress) {
            revert NotYourBid();
        }

        uint256 amount = currentBid.value;

        currentBid = Bid({ active: false, value: 0, fromAddress: address(0) });

        _sendFunds(amount);

        emit BidWithdrawn(amount, msg.sender);
    }

    function setRoyaltyRecipient(address newRoyaltyRecipient) public onlyRoyaltyRecipient {
        if (newRoyaltyRecipient == address(0)) {
            revert NullAddress();
        }

        royaltyRecipient = newRoyaltyRecipient;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;

        owner = newOwner;

        emit ArtpieceTransferred(oldOwner, newOwner);
    }

    function _sendFunds(uint256 amount) internal virtual {
        (bool success, ) = msg.sender.call{value: amount}('');

        if (!success) {
            revert FundsTransfer();
        }
    }

    function _calcRoyalty(uint256 amount) internal virtual returns (uint256) {
        return (amount * royaltyPercentage) / 100;
    }
}
