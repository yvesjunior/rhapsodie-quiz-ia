<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title><?= lang('languages'); ?> | <?php echo (is_settings('app_name')) ? is_settings('app_name') : "" ?></title>

    <?php base_url() . include 'include.php'; ?>
</head>

<body>
    <div id="app">
        <div class="main-wrapper">
            <?php base_url() . include 'header.php'; ?>

            <!-- Main Content -->
            <div class="main-content">
                <section class="section">
                    <div class="section-header">
                        <h1><?= lang('languages'); ?></h1>
                    </div>
                    <div class="section-body">
                        <div class="row">
                            <div class="col-12 col-sm-12 col-md-2">
                                <div class="card">
                                    <div class="card-body">
                                        <ul class="nav nav-pills flex-column" id="languagesTab" role="tablist">
                                            <?php if ($has_languages_permission) { ?>
                                            <li class="nav-item">
                                                <a class="nav-link active" id="quiz-languages-tab" data-toggle="tab" href="#quizLanguages" role="tab"
                                                    aria-controls="quizLanguages" aria-selected="true"><?= lang('languages'); ?></a>
                                            </li>
                                            <?php } ?>
                                            <?php if ($has_system_languages_permission) { ?>
                                            <li class="nav-item">
                                                <a class="nav-link <?= !$has_languages_permission ? 'active' : '' ?>" id="system-languages-tab" data-toggle="tab" href="#systemLanguages" role="tab"
                                                    aria-controls="systemLanguages" aria-selected="<?= !$has_languages_permission ? 'true' : 'false' ?>"><?= lang('system_languages'); ?></a>
                                            </li>
                                            <?php } ?>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                            <div class="col-12 col-sm-12 col-md-10">
                                <div class="tab-content no-padding" id="languagesTabContent">
                                    <?php if ($has_languages_permission) { ?>
                                    <div class="tab-pane fade show active" id="quizLanguages" role="tabpanel" aria-labelledby="quiz-languages-tab">
                                        <div class="row">
                                            <div class="col-12">
                                                <div class="card">
                                                    <div class="card-header">
                                                        <h4><?= lang('create_language'); ?></h4>
                                                    </div>
                                                    <div class="card-body">
                                                        <form method="post" class="needs-validation" novalidate="">
                                                            <?php
                                                            $sess_language_name = '';
                                                            $sess_language_code = '';
                                                            if ($this->session->userdata()) {
                                                                $sess_data = $this->session->userdata();
                                                                if (!empty($sess_data)) {
                                                                    $sess_language_name = $sess_data['language_name'] ?? null;
                                                                    $sess_language_code = $sess_data['language_code'] ?? null;
                                                                }
                                                            }
                                                            ?>
                                                            <input type="hidden" name="<?= $this->security->get_csrf_token_name(); ?>" value="<?= $this->security->get_csrf_hash(); ?>">
                                                            <div class="row">
                                                                <div class="form-group col-md-6">
                                                                    <label class="control-label"><?= lang('language_name'); ?> <small class="text-danger">*</small></label>
                                                                    <input name="language_name" class="form-control language-name" required placeholder="<?= lang('language_name'); ?>">
                                                                </div>
                                                                <div class="form-group col-md-6">
                                                                    <label class="control-label"><?= lang('language_code'); ?> <small class="text-danger">*</small></label>
                                                                    <input name="language_code" class="form-control language-code" required placeholder="<?= lang('language_code'); ?>">
                                                                </div>
                                                                <div class="form-group col-md-2 col-sm-6">
                                                                    <label class="control-label">&nbsp;</label><br />
                                                                    <input type="submit" name="btncreate" value="<?= lang('submit'); ?>" class="<?= BUTTON_CLASS ?>" />
                                                                </div>
                                                            </div>
                                                        </form>
                                                    </div>
                                                </div>

                                                <div class="card">
                                                    <div class="card-header">
                                                        <h4><?= lang('add_languages'); ?></h4>
                                                    </div>
                                                    <div class="card-body">
                                                        <form method="post" class="needs-validation" novalidate="">
                                                            <input type="hidden" name="<?= $this->security->get_csrf_token_name(); ?>" value="<?= $this->security->get_csrf_hash(); ?>">
                                                            <div class="row">
                                                                <div class="form-group col-md-6 col-sm-12">
                                                                    <label class="control-label"><?= lang('select_language'); ?> <small class="text-danger">*</small></label>
                                                                    <select name="language_id" class="form-control" required>
                                                                        <option value=""><?= lang('select_language'); ?></option>
                                                                        <?php foreach ($language as $lang) { ?>
                                                                            <option value="<?= $lang->id ?>"><?= $lang->language ?></option>
                                                                        <?php } ?>
                                                                    </select>
                                                                </div>
                                                                <div class="form-group col-md-2 col-sm-6">
                                                                    <label class="control-label">&nbsp;</label><br />
                                                                    <input type="submit" name="btnadd" value="<?= lang('submit'); ?>" class="<?= BUTTON_CLASS ?>" />
                                                                </div>
                                                            </div>
                                                        </form>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="col-12">
                                                <div class="card">
                                                    <div class="card-header">
                                                        <h4><?= lang('languages'); ?> <small><?= lang('view_update_delete'); ?></small></h4>
                                                    </div>
                                                    <div class="card-body">
                                                        <table aria-describedby="mydesc" class='table-striped' id='languages_list' data-toggle="table" data-url="<?= base_url() . 'Table/languages' ?>" data-click-to-select="true" data-side-pagination="server" data-pagination="true" data-page-list="[5, 10, 20, 50, 100, 200, All]" data-search="true" data-toolbar="#toolbar" data-show-columns="true" data-show-refresh="true" data-trim-on-search="false" data-mobile-responsive="true" data-sort-name="id" data-sort-order="desc" data-maintain-selected="true" data-show-export="true" data-export-types='["csv","excel","pdf"]' data-export-options='{ "fileName": "languages-list-<?= date('d-m-y') ?>" }' data-query-params="queryParams">
                                                            <thead>
                                                                <tr>
                                                                    <th scope="col" data-field="id" data-sortable="true"><?= lang('id'); ?></th>
                                                                    <th scope="col" data-field="language" data-sortable="true"><?= lang('language_name'); ?></th>
                                                                    <th scope="col" data-field="code" data-sortable="true" data-visible="false"><?= lang('language_code'); ?></th>
                                                                    <th scope="col" data-field="status" data-sortable="false" data-formatter="statusFormatter"><?= lang('status'); ?></th>
                                                                    <th scope="col" data-field="default_active" data-sortable="false" data-formatter="defaultFormatter"><?= lang('default'); ?></th>
                                                                    <th scope="col" data-field="operate" data-sortable="false" data-events="actionEvents"><?= lang('operate'); ?></th>
                                                                </tr>
                                                            </thead>
                                                        </table>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <?php } ?>
                                    <?php if ($has_system_languages_permission) { ?>
                                    <div class="tab-pane fade <?= !$has_languages_permission ? 'show active' : '' ?>" id="systemLanguages" role="tabpanel" aria-labelledby="system-languages-tab">
                                        <div style="padding: 20px;">
                                            <p class="text-muted mb-3">
                                                <a href="<?= base_url() ?>system-languages" target="_blank" class="btn btn-sm btn-outline-primary float-right">
                                                    <i class="fas fa-external-link-alt"></i> <?= lang('open_in_new_tab'); ?>
                                                </a>
                                            </p>
                                            <iframe src="<?= base_url() ?>system-languages/content?iframe=1" style="width: 100%; border: 1px solid #ddd; min-height: 1000px; border-radius: 4px;" id="systemLanguagesFrame"></iframe>
                                        </div>
                                    </div>
                                    <?php } ?>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
            </div>
        </div>
    </div>

    <div class="modal fade" tabindex="-1" role="dialog" id="editDataModal">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><?= lang('edit_language'); ?></h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <div class="card-body">
                        <form method="post" class="needs-validation" novalidate="" enctype="multipart/form-data">
                            <input type="hidden" name="<?= $this->security->get_csrf_token_name(); ?>" value="<?= $this->security->get_csrf_hash(); ?>">
                            <input type='hidden' name="edit_id" id="edit_id" value="" />
                            <div class="row">
                                <div class="form-group col-sm-12">
                                    <label class="control-label"><?= lang('language_name'); ?> <small class="text-danger">*</small></label>
                                    <input name="language_name" class="form-control edit-language-name" required placeholder="<?= lang('language_name'); ?>">
                                </div>
                                <div class="form-group col-sm-12">
                                    <label class="control-label"><?= lang('language_code'); ?> <small class="text-danger">*</small></label>
                                    <input name="language_code" class="form-control edit-language-code" required placeholder="<?= lang('language_code'); ?>">
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-6 col-sm-12">
                                    <label class="control-label"><?= lang('status') ?></label><br>
                                    <input type="checkbox" id="status" name="status" data-plugin="switchery">
                                </div>
                                <div class="form-group col-md-6 col-sm-12">
                                    <label class="control-label"><?= lang('default') ?></label><br>
                                    <input type="checkbox" id="default" name="default_active" data-plugin="switchery">
                                </div>
                            </div>
                            <div class="float-right">
                                <button type="button" class="btn btn-secondary" data-dismiss="modal"><?= lang('close'); ?></button>
                                <input name="btnupdate" type="submit" value="<?= lang('save_changes'); ?>" class="<?= BUTTON_CLASS ?>">
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <?php base_url() . include 'footer.php'; ?>

    <script type="text/javascript">
        $('[data-plugin="switchery"]').each(function(index, element) {
            var init = new Switchery(element, {
                size: 'small',
                color: '#1abc9c',
                secondaryColor: '#f1556c'
            });
        });
        $('[data-plugin="switchery"]').on('change', function() {
            if ($(this).prop('checked') == true) {
                $(this).val(1);
            } else {
                $(this).val(0);
            }
        })
    </script>
    <script type="text/javascript">
        var sess_language_name = '<?= isset($sess_language_name) ? $sess_language_name : '' ?>';
        var sess_language_code = '<?= isset($sess_language_code) ? $sess_language_code : '' ?>';
        $(document).ready(function() {
            if (sess_language_name) $('.language-name').val(sess_language_name);
            if (sess_language_code) $('.language-code').val(sess_language_code);

            // Adjust iframe height
            $('#systemLanguagesFrame').on('load', function() {
                try {
                    var iframe = this;
                    var iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                    iframe.style.height = iframeDoc.body.scrollHeight + 'px';
                } catch (e) {
                    // Cross-origin restriction, set default height
                    iframe.style.height = '1200px';
                }
            });

            // Handle tab switching
            $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
                var target = $(e.target).attr("href");
                if (target === '#systemLanguages') {
                    // Reload iframe when switching to system languages tab
                    $('#systemLanguagesFrame').attr('src', $('#systemLanguagesFrame').attr('src'));
                }
            });
        });

        window.actionEvents = {
            'click .edit-data': function(e, value, row, index) {
                $('#edit_id').val(row.id);
                $('.edit-language-name').val(row.language);
                $('.edit-language-code').val(row.code);
                $('#status').val(row.status);
                $("#status").prop("checked", true).trigger("click");
                if (row.status == 1) {
                    $("#status").prop("checked", false).trigger("click");
                }
                $('#default').val(row.default_active);
                $("#default").prop("checked", true).trigger("click");
                if (row.default_active == 1) {
                    $("#default").prop("checked", false).trigger("click");
                }
            }
        };

        function statusFormatter(value, row) {
            let html = "";
            if (row.status == 1) {
                html = "<span class='badge badge-success'><?= lang('enabled'); ?></span>";
            } else {
                html = "<span class='badge badge-danger'><?= lang('disabled'); ?></span>";
            }
            return html;
        }

        function defaultFormatter(value, row) {
            let html = "";
            if (row.default_active == 1) {
                html = "<span class='badge badge-success'><?= lang('yes'); ?></span>";
            } else {
                html = "<span class='badge badge-danger'><?= lang('no'); ?></span>";
            }
            return html;
        }

        $(document).on('click', '.delete-data', function() {
            if (confirm("<?= lang('delete_language'); ?>")) {
                var base_url = "<?= base_url(); ?>";
                id = $(this).data("id");
                $.ajax({
                    url: base_url + 'delete_language',
                    type: "POST",
                    data: 'id=' + id,
                    success: function(result) {
                        if (result) {
                            $('#languages_list').bootstrapTable('refresh');
                        } else {
                            var PERMISSION_ERROR_MSG = "<?= lang(PERMISSION_ERROR_MSG); ?>";
                            ErrorMsg(PERMISSION_ERROR_MSG);
                        }
                    }
                });
            }
        });

        function queryParams(p) {
            return {
                sort: p.sort,
                order: p.order,
                offset: p.offset,
                limit: p.limit,
                search: p.search
            };
        }
    </script>

</body>

</html>

