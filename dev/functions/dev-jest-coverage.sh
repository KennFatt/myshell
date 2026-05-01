if [[ -f $jest_bin ]]; then
    # node node_modules/jest/bin/jest.js Counter.test.tsx --coverage --reporters=jest-junit --watchAll=false --coverageDirectory=reportcoverage -c ./jest.config.ts -t 'Counter'
    function dev-jest-coverage() {
        if [[ -z $1 ]]; then
            echo "Usage: $0 <file_name: string|regex> <test_name: string|regex>"
            echo "Example: $0 Counter.test.tsx 'Counter component'"
            return
        fi

        local reportcoverage_dir='reportcoverage'

        # test cleanup
        rm -rf junit.xml $reportcoverage_dir

        # run the jest
        $node_bin $jest_bin $1 \
            --runInBand \
            --coverage \
            --reporters=default \
            --verbose \
            --reporters=jest-junit \
            --coverageReporters=html \
            --coverageDirectory=$reportcoverage_dir \
            --collectCoverageFrom=''

        local jest_coverage_report=$reportcoverage_dir/index.html

        # open the output in browser
        local report_file_path=$(pwd)/$jest_coverage_report
        echo "Opening file: $report_file_path in the brower..."
        $chromium_bin --app=file://$report_file_path >/dev/null 2>&1 &
        disown
    }
fi
