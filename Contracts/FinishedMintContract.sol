// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Z.sol";

contract MintContract is ERC721Z {

    uint256 public _amountForMintListSale;
    uint256 public _amountForAuctionSale;
    uint256 public _amountForDevMint;
    uint16 public MaxSupply = 8888;
    uint8 public MaxMintsPerWallet = 1;
    uint8 public MaxMintsPerMintlistWallet = 2;
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() ERC721Z("Name", "Symbol") {
        _transferOwnership(_msgSender());
        SaleConfig.isPublicSaleOn = false;
        SaleConfig.isMintlistSaleOn = false;
        _amountForAuctionSale = 8000;
        _amountForMintListSale = 400;
        _amountForDevMint = 50;

    }

    // sale information
    struct SaleConfiguration {
        uint64 _auctionStartTime;
        uint64 _mintPrice;
        bool isPublicSaleOn;
        bool isMintlistSaleOn;
    }

    SaleConfiguration public SaleConfig;

    // mappings
    mapping(uint256 => uint256) priceOf;
    mapping(address => bool) public hasClaimed;
    mapping(address => bool) public isMintlisted;

    // modifier function pair to check the caller is not a contract
    function _callerIsUser() internal virtual {
        require(tx.origin == msg.sender, "Function caller is another contract!");
    }
    modifier callerIsUser() {
        _callerIsUser();
        _;
    }

    // OZ Ownerable logic
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    // modifier that calls function saves gas
    function _onlyOwner() internal virtual {
        require(owner() == _msgSender(), "Function caller is not the owner");
    }
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
     
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


    // External only owner functions (withdraw/set sale configuration)
    function setPublicMint(bool _saleOnOrOf) public virtual onlyOwner {
        SaleConfig.isPublicSaleOn = _saleOnOrOf;
        SaleConfig._mintPrice = 0.1 ether;
    }
    function setAuctionMint(uint64 _startTime) public virtual onlyOwner {
        SaleConfig._auctionStartTime = _startTime;
    }
    function setMintlistMint(bool _saleOnOrOf) public virtual onlyOwner {
        SaleConfig.isMintlistSaleOn = _saleOnOrOf;
        SaleConfig._mintPrice = 0.1 ether;
    }

    // add user to mintlist
    function MintlistUser(address addr_) external onlyOwner {
        isMintlisted[addr_] = true;
    }

    // owner withdraw of funds
    function withdraw(address to_) external onlyOwner {
        payable(to_).transfer(address(this).balance);
    }


    uint64 public AuctionStartPrice = 2 ether;
    uint64 public AuctionPriceDropPerInterval = 0.1 ether;
    uint64 public AuctionEndPrice = 0.1 ether;
    uint32 public AuctionLength = 190 minutes;
    uint16 public AuctionDropInterval = 10 minutes;

    function _getTokenId() internal view returns (uint256) {
        return totalSupply + 1;
    }
    
    // gets the auction price based on the time
    function getAuctionMintPrice() internal view virtual returns (uint256) {
        if (block.timestamp < SaleConfig._auctionStartTime) {
            return AuctionStartPrice;
        }
        if (block.timestamp - SaleConfig._auctionStartTime >= AuctionLength) {
            return AuctionEndPrice;
        } else {
            uint256 NumOfIntervals = uint256((block.timestamp - SaleConfig._auctionStartTime) / AuctionDropInterval);
            uint256 AuctionPriceAtInterval = AuctionStartPrice - (AuctionPriceDropPerInterval * NumOfIntervals);
            return AuctionPriceAtInterval;
        }
    }

    // auction mint function
    function AuctionMint(uint32 amount_) external payable callerIsUser {
        require(block.timestamp > SaleConfig._auctionStartTime, "Auction not started!");
        require(amount_ == MaxMintsPerWallet, "Invalid mint amount requested!");
        require(balanceOf[msg.sender] == 0, "Maximum number of NFTs already minted!");
        require(msg.value == getAuctionMintPrice(), "Invalid amount of ETH!");

        priceOf[_getTokenId()] = msg.value;
        _mint(msg.sender, _getTokenId());
    }

    // refunds the difference of a user's bid from the lowest bid in the auction
    function _refundDifference() external onlyOwner {
        address[] memory UserAddresses = new address[](auctionSupply);
        uint256[] memory PricesOfTokens = new uint256[](auctionSupply);
        uint256 index_;
        uint256 finalPrice = priceOf[8888];
        for(uint256 i = 0; i < auctionSupply; i++) {
            UserAddresses[i] = ownerOf[index_];
            PricesOfTokens[i] = priceOf[index_];
            index_++;
        }
        for(uint256 i = 0; i < auctionSupply; i++) {
            payable(UserAddresses[i]).transfer(PricesOfTokens[i] - finalPrice);
        }
    }

    // mint list
    function mintlistMint(uint256 amount_) external payable callerIsUser {
        require(SaleConfig.isMintlistSaleOn, "Mintlist sale has not started!");
        require(isMintlisted[msg.sender], "You are not on the mintlist!");
        require(hasClaimed[msg.sender] != true, "All mints have been claimed!");
        require((totalSupply + amount_) < (_amountForAuctionSale + _amountForMintListSale + 1),
        "Max supply has been reached!");
        require(amount_ < MaxMintsPerMintlistWallet + 1); //as 2 + 1 = 3 and max < 3 = 2
        uint256[] memory tokens = new uint256[](amount_);
        for(uint256 i = 0; i < amount_; i++) {
            tokens[i] = _getTokenId() + i;
            _mint(msg.sender, tokens[i]);
        }
    }
    
    // dev mint for team and marketing etc
    function devMint(uint256 amount_) external onlyOwner {
        require(totalSupply < MaxSupply, "Max supply has been reached!");
        require(_amountForDevMint % amount_ = 0, "Invalid mint amount!");
        require(amount_ < _amountForDevMint + 1, "Invalid number of mints requested");

        uint256[] memory tokenIds = new uint256[](amount_);
        for(uint256 i = 0; i < amount_; i++) {
            tokenIds[i] = i;
        }
        _mint(_owner, tokenIds);
    }

    /*
    public mint for the remainder of the nfts
    */
    function publicMint(uint256 amount_) external payable callerIsUser {
        require(SaleConfig.isPublicSaleOn, "Public sale has not started!");
        require(totalSupply < MaxSupply, "Max supply has been reached!");
        require(amount_ < MaxMintsPerWallet + 1, "Invalid number of mints requested!");
        require(msg.value == SaleConfig._mintPrice, "Invalid amount of ETH to mint!");

        _mint(msg.sender, _getTokenId());
    }

}