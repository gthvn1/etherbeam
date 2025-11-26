default: build

build : build_raw_binder build_etherbeam
run: run_raw_binder run_etherbeam

[working-directory: 'go']
@build_raw_binder:
    echo 'Building raw_binder'
    go build .

[working-directory: 'go']
@run_raw_binder:
    echo 'Running raw_binder'
    go run .

[working-directory: 'gleam']
@build_etherbeam:
    echo 'Building etherbeam'
    gleam build

[working-directory: 'gleam']
@run_etherbeam:
    echo 'Running etherbeam'
    gleam run
