'use strict';

angular.module('myApp.view1', ['ngRoute'])

.config(['$routeProvider', function($routeProvider) {
  $routeProvider.when('/view1', {
    templateUrl: 'view1/view1.html',
    controller: 'View1Ctrl'
  });
}])

.controller('View1Ctrl', ['$scope', '$location', function($scope) {


        $scope.errorMessage = "";
        $scope.isShowError = false;

        $scope.boardId = '5667ef0342970bb6b57a9a7b';
        $scope.listIds = [];

        //.activities [array of {Date = timestamp, String = location, String = details/brief desc}]
        $scope.mockTrackCards = [
            {id: "84770001313257", status: 5, service: "Package", destination: "Australia", eta: new Date(),
            activities: []},
            {id: "84770045783279", status: 3, service: "Envelope", destination: "UK", eta: new Date(),
                activities: [
                    {date: new Date().toDateString(), location: "in transit", details: "driver picked up pkg and just sitting on it"},
                    {date: new Date().toDateString(), location: "Dndg warehouse", details: "left the warehouse"},
                    {date: new Date().toDateString(), location: "order arrived", details: "package prepared"}]
            }
        ];

        $scope.mapStatusToList = ["Unknown", "Shipping", "En Route", "Out For Delivery", "Delivered", "Delayed"];
        $scope.mapStatusToListId = [
            "566929d3c2513c02f21c0af0",
            "5667f46ef874f6c34cd7a4d9",
            "5667f49b823adf08e2cb55b1",
            "56692349bc218f7002b8f47c",
            "5667f471d217c655cbadf3e9",
            "5669237571e7694e20db6bfe"];


        /***
         *
         */
        $scope.getListsOnBoard = function() {

            Trello.authorize(
                {
                    type: "popup",
                    name: "Getting Started Application",
                    scope: {
                        read: true,
                        write: true },
                    expiration: "never",
                    authenticationSuccess,
                    authenticationFailure
                });

            // get all the listIds
            Trello.get('/boards/' + $scope.boardId + '/lists', $scope.getListsSuccess, $scope.getListsError);
        };

        // capture all the lists info
        $scope.getListsSuccess = function(data){
            $scope.listIds = data;
            console.log($scope.listIds);

            $scope.createCards();

        };


        /***
         * will be called if get lists is successful
         */
        $scope.createCards = function() {

            if ($scope.mockTrackCards == null || $scope.mockTrackCards.length <= 0) {
                return;
            }

            for (var i=0 ; i< $scope.mockTrackCards.length ; i++) {
                var mockCard =  $scope.mockTrackCards[i];

                var listName = $scope.mapStatusToList[mockCard.status];
                console.log("list name " + listName);

                //var listId = $scope.mapStatusToListId[mockCard.status];
                var listId = $scope.getListId(listName);
                console.log("list id " + listId);

                var cardName = "Track ID:" + mockCard.id;

                var cardDescription = $scope.createDescription(mockCard);

                $scope.createCard(cardName, cardDescription, listId);

            }
        };

        $scope.createDescription = function(trackInfo) {
            var description = "![](http://localhost:8000/app/resources/box20.png) Shipments" +
            "\n=========\n" +
            "Package # " + trackInfo.id + " on AusPost" +
            "\n------------------------------------------------\n" +
            "ETA:" + trackInfo.eta + " [Track on AusPost site](http://www.auspost.com.au)\n\n\n";

            if (trackInfo.status >= 1 && trackInfo.status <= 3) {
                // in transit image
                description += "![](http://localhost:8000/app/resources/in-transit.png)\n\n";
            }
            else if (trackInfo.status == 4) {
                // delivered image
                description += "![](http://localhost:8000/app/resources/delivered.png)\n\n";
            }
            else if (trackInfo.status == 5 || trackInfo.status == 0) {
                // processed image
                description += "![](http://localhost:8000/app/resources/processed.png)\n\n";
            }

            for (var i =0  ; i< trackInfo.activities.length ; i++ ) {
                var entry = "- **location:** " + trackInfo.activities[i].location +
                    "   **date:** " + trackInfo.activities[i].date +
                    "   **details:** " + trackInfo.activities[i].details + "\n";

                description += entry;
            }

            console.log(description);

            return description;
        };

        // capture all the lists info error
        $scope.getListsError = function(data){
            $scope.errorMessage = data;
            $scope.isShowError = true;
        };

        $scope.getListId = function(listName) {

            for (var i=0 ; i< $scope.listIds.length ; i++) {
                if ($scope.listIds[i].name == listName) {
                    return $scope.listIds[i].id;
                }
            }

            return null;
        };

        $scope.closeErrorMessage = function() {
            $scope.isShowError = false;
            $scope.errorMessage = "";
        };

        $scope.init = function() {
            console.log("View1 init");
        };

        /***
         *
         * @param name
         * @param description
         * @param listId
         */
        $scope.createCard = function(name, description, listId) {

            //Trello.authorize({
            //    type: "popup",
            //    name: "Getting Started Application",
            //    scope: {
            //        read: true,
            //        write: true },
            //    expiration: "never",
            //    authenticationSuccess,
            //    authenticationFailure
            //});


            var myList = listId;

            var newCard = {
                name: name,
                desc: description,
                pos: "top",
                idList: myList
            };

            Trello.post("/cards", newCard, $scope.createCardSuccess);
        };

        $scope.createCardSuccess = function(data) {

            console.log("Card created successfully. Data returned:" + JSON.stringify(data));

            $scope.errorMessage += " Successfully created card id: " + data.id;
            $scope.isShowError = true;

            // add a post logo attachment
            // /Users/manori/TrelloTracker/app/resources/post-logo-36.png
            //Trello.post("/cards/" + data.id + "/attachments",
            //    { 'Content-Disposition':"form-data", name:"file", filename:"post-logo-36.png", 'Content-Type': "image/png"},
            //    $scope.createCardAttachmentSuccess);

        };

        $scope.createCardAttachmentSuccess = function(data) {

            console.log("Card created attachment successfully. Data returned:" + JSON.stringify(data));

            $scope.errorMessage += " Successfully created attachment for card id: " + data.id;
            $scope.isShowError = true;
        };

        var authenticationSuccess = new function() { console.log("Successful authentication"); };
        var authenticationFailure = new function() { console.log("Failed authentication"); };

        $scope.init();
}]);



