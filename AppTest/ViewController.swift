//
//  ViewController.swift
//  AppTest
//
//

import NMAKit

class ViewController: UIViewController {

    @IBOutlet private weak var mapView: NMAMapView!
    @IBOutlet private weak var mapDownloadProgressLabel: UILabel!
    @IBOutlet private weak var buildLongButton: UIButton!
    @IBOutlet private weak var buildShortButton: UIButton!
    
    private lazy var mapLoader: NMAMapLoader = {
        let mapLoader = NMAMapLoader.sharedInstance()
        mapLoader.delegate = self
        mapLoader.select(.truckAttributes)
        mapLoader.select(.realisticViews16x9)
        return mapLoader
    }()

    private lazy var navigationManager: NMANavigationManager = {
        let manager = NMANavigationManager.sharedInstance()
        manager.mapTrackingEnabled = true
        manager.mapTrackingAutoZoomEnabled = true
        manager.mapTrackingOrientation = .dynamic
        manager.mapTrackingTilt = .tilt3D
        manager.isVoiceEnabled = true
        manager.isSpeedWarningAudioFeedbackEnabled = true
        manager.voicePackageMeasurementSystem = .imperialUS
        manager.backgroundNavigationEnabled = true
        manager.setTrafficAvoidanceMode(.manual)
        manager.setLowSpeedOffset(10, highSpeedOffset: 10, speedBoundary: 0)
        manager.realisticViewMode = .day
        manager.realisticViewAspectRatios = .view16x9
        return manager
    }()

    private lazy var router = NMACoreRouter()
    private let stopovers: [NMAWaypoint] = [
        .init(geoCoordinates: .init(latitude: 34.22892, longitude: -81.5484), waypointType: .stopWaypoint),
        .init(geoCoordinates: .init(latitude: 33.63999, longitude: -84.5211), waypointType: .stopWaypoint),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.copyrightLogoPosition = .bottomRight
        mapView.projectionType = .globe
        mapView.mapScheme = NMAMapSchemeNormalDay
        mapView.extrudedBuildingsVisible = false
        mapView.landmarksVisible = false
        mapView.safetySpotsVisible = false
        mapView.transitDisplayMode = .nothing
        mapView.hide(fleetFeature: .congestionZones)
        mapView.hide(fleetFeature: .environmentalZones)
        mapView.setVisibility(false, for: .all)
        mapView.setVisibility(false, for: [
            NSNumber(integerLiteral: NMAMapLayerCategory.poiIcon.rawValue),
            NSNumber(integerLiteral: NMAMapLayerCategory.poiLabel.rawValue)
        ])
        mapView.disableMapGestures([.longPress, .rotate, .twoFingerPan])
        mapView.isTrafficVisible = true
        mapView.hide(trafficLayers: [.flow, .incidents])
        mapView.show(trafficLayers: .onRoute)
        mapView.positionIndicator.isVisible = true
        mapView.positionIndicator.accuracyIndicatorColor = .green.withAlphaComponent(0.2)
        mapView.positionIndicator.isAccuracyIndicatorVisible = true
        mapView.transformCenter = .init(x: 0.5, y: 0.65)
        navigationManager.map = mapView
    }
    
    @IBAction func didTouchBuildRouteWithLongTruck(_ sender: UIButton) {
        let routingMode = getRoutingMode(long: true)
        let penalty = NMADynamicPenalty()
        penalty.trafficPenaltyMode = .optimal
        router.dynamicPenalty = penalty
        router.connectivity = .online
        router.calculateRoute(withStops: stopovers, routingMode: routingMode) { result, error in
            guard let route = result?.routes?.first, let mapRoute = NMAMapRoute(route) else { return }
            mapRoute.color = .red
            mapRoute.upcomingColor = .purple
            mapRoute.traveledColor = .gray
            mapRoute.isTrafficEnabled = true
            self.mapView.add(mapObject: mapRoute)
            route.boundingBox.map { self.mapView.set(boundingBox: $0, animation: .none) }
            self.navigationManager.startTurnByTurnNavigation(route)
        }
    }
    
    @IBAction func didTouchBuildRouteWithShortTruck(_ sender: UIButton) {
        let routingMode = getRoutingMode(long: false)
        let penalty = NMADynamicPenalty()
        penalty.trafficPenaltyMode = .optimal
        router.dynamicPenalty = penalty
        router.connectivity = .online
        router.calculateRoute(withStops: stopovers, routingMode: routingMode) { result, error in
            guard let route = result?.routes?.first, let mapRoute = NMAMapRoute(route) else { return }
            mapRoute.color = .red
            mapRoute.upcomingColor = .purple
            mapRoute.traveledColor = .gray
            mapRoute.isTrafficEnabled = true
            self.mapView.add(mapObject: mapRoute)
            route.boundingBox.map { self.mapView.set(boundingBox: $0, animation: .none) }
            self.navigationManager.startTurnByTurnNavigation(route)
        }
    }
    
    @IBAction func didTouchGetMapPackages(_ sender: UIButton) {
        mapLoader.getMapPackages()
    }
}

private extension ViewController {
    
    private func getRoutingMode(long: Bool) -> NMARoutingMode {
        let routingMode = NMARoutingMode()
        routingMode.routingType = .fastest
        routingMode.transportMode = .truck
        routingMode.resultLimit = 3
        routingMode.vehicleWidth = 2.5908
        routingMode.vehicleHeight = 4.11
        routingMode.vehicleLength = long == true ? 22.86 : 9.15
        routingMode.weightPerAxle = 0
        routingMode.limitedVehicleWeight = 13
        routingMode.trailersCount = 1
        routingMode.truckAxleCount = 3
        routingMode.avoidDifficultTurns = false
        routingMode.truckRestrictionsMode = .noViolations
        routingMode.truckType = .tractorTruck
        routingMode.tunnelCategory = .none
        routingMode.routingOptions = []
        return routingMode
    }
}
// MARK: - NMAMapLoaderDelegate

extension ViewController: NMAMapLoaderDelegate {
    
    func mapLoader(_ mapLoader: NMAMapLoader, didGetPackages mapLoaderResult: NMAMapLoaderResult) {
        if mapLoaderResult == .success {
            checkPackages(with: mapLoader)
        }
    }

    private func checkPackages(with mapLoader: NMAMapLoader) {
        let northAmerica = mapLoader.rootPackage?.children.first { $0.packageId == 8 }
        if let package = northAmerica?.children.first(where: { $0.packageId == 1000 }) {
            checkStatus(for: package)
        }
    }

    private func checkStatus(for package: NMAMapPackage) {
        switch package.installationStatus {
        case .none, .partiallyInstalled:
            mapLoader.install([package])
        default:
            break
        }
    }

    func mapLoader(_ mapLoader: NMAMapLoader, didUpdate progress: Float) {
        print(progress)
        mapDownloadProgressLabel.text = "Map loading progress = \(progress)"
    }

    func mapLoader(_ mapLoader: NMAMapLoader, didInstallPackages mapLoaderResult: NMAMapLoaderResult) {
        print("installed")
    }
}
